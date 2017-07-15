module CarrierWave
  module Extensions
    module VideoMultiThumbnailer
      def create_thumbnails_for_video(format, opts = {})
        prepare_thumbnailing_parameters_by(format, opts)
        # Create temprorary directory where all created thumbnails would be saved
        prepare_tmp_dir

        run_thumbnails_transcoding

        # Run callback for saving thumbnails
        save_thumb_files
        # Remove temporary data
        remove_tmp_dir
      end

      private

      def run_thumbnails_transcoding
        with_trancoding_callbacks do
          if @progress
            @file.screenshot(*screenshot_options) do |value|
              progress.call(value)
            end
            # It is ugly hack but this operation returned this in the end
            # 0.8597883597883599 that is not 1.0
            @progress.call(1.0)
          else
            @file.screenshot(*screenshot_options)
          end
        end
      end

      def prepare_thumbnailing_parameters_by(format, opts)
        # move upload to local cache
        cache_stored_file! unless cached?

        # This `custom: []` is needed to avoid error at
        # CarrierWave::Video::FfmpegOptions#format_params
        @options = CarrierWave::Video::FfmpegOptions.new(
          format, opts.merge(custom: [])
        )

        @file = ::FFMPEG::Movie.new(current_path)

        if opts[:resolution] == :same
          @options.format_options[:resolution] = @file.resolution
        end

        yield(@file, @options.format_options) if block_given?

        @progress = @options.progress(model)
      end

      def base_tmp_dir_path
        "#{::Rails.root}/tmp/videos/#{model.id}"
      end

      def tmp_dir_path
        "#{base_tmp_dir_path}/thumbnails"
      end

      def prepare_tmp_dir
        FileUtils.mkdir_p(tmp_dir_path)
      end

      def remove_tmp_dir
        FileUtils.rm_rf(base_tmp_dir_path) if Dir.exist?(base_tmp_dir_path)
      end

      # Thumbnails are sorted by their creation date
      # to align then in chronological order.
      def thumb_file_paths_list
        Dir["#{tmp_dir_path}/*.#{@options.format}"].sort_by do |filename|
          File.mtime(filename)
        end
      end

      def save_thumb_files
        model.send(@options.raw[:save_thumbnail_files_method], thumb_file_paths_list)
      end

      def screenshot_options
        [
          "#{tmp_dir_path}/%d.#{@options.format}",
          @options.format_params,
          {
            preserve_aspect_ratio: :width,
            validate: false
          }
        ]
      end
    end
  end
end
