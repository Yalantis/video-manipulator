module CarrierWave::Extensions::VideoMultiThumbnailer

  THUMBNAIL_FORMAT = 'jpg'

  def create_thumbnails_for_video(format, opts = {})
    # move upload to local cache
    cache_stored_file! unless cached?

    @options = CarrierWave::Video::FfmpegOptions.new(format, opts)
    tmp_path = File.join(File.dirname(current_path), "tmpfile.#{format}")
    file = ::FFMPEG::Movie.new(current_path)

    if opts[:resolution] == :same
      @options.format_options[:resolution] = file.resolution
    end

    if opts[:video_bitrate] == :same
      @options.format_options[:video_bitrate] = file.video_bitrate
    end

    yield(file, @options.format_options) if block_given?

    progress = @options.progress(model)

    prepare_tmp_dir

    with_trancoding_callbacks do
      if progress
        file.screenshot(*screenshot_options) do |value|
          progress.call(value)
        end
        # It is ugly hack but this operation returned this in the end
        # 0.8597883597883599 that is not 1.0
        progress.call(1.0)
      else
        file.screenshot(*screenshot_options)
      end
    end

    save_thumb_files
    remove_tmp_dir
  end

  private

  def tmp_dir_path
    "#{::Rails.root}/tmp/videos/#{model.id.to_s}/thumbnails"
  end

  def prepare_tmp_dir
    FileUtils.mkdir_p(tmp_dir_path)
  end

  def remove_tmp_dir
    FileUtils.rm_rf(tmp_dir_path) if Dir.exists?(tmp_dir_path)
  end

  def thumb_file_paths_list
    Dir["#{tmp_dir_path}/*.#{THUMBNAIL_FORMAT}"].sort
  end

  def save_thumb_files
    model.send(@options.raw[:save_thumbnail_files_method], thumb_file_paths_list)
  end

  def screenshot_options
    [
      "#{tmp_dir_path}/%d.#{THUMBNAIL_FORMAT}",
      @options.format_params,
      {
        preserve_aspect_ratio: :width,
        validate: false
      }
    ]
  end

end
