module CarrierWave
  module Extensions
    module VideoMetadata
      def read_video_metadata(format, opts = {})
        # move upload to local cache
        cache_stored_file! unless cached?

        @options = CarrierWave::Video::FfmpegOptions.new(format, opts)

        file = ::FFMPEG::Movie.new(current_path)

        if opts[:save_metadata_method]
          model.send(opts[:save_metadata_method], file.metadata)
        end

        progress = @options.progress(model)

        with_trancoding_callbacks do
          # Here it happens instantly so we provide here value for 100%
          progress&.call(1.0)
        end
      end
    end
  end
end
