class VideoUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay
  include ::CarrierWave::Extensions::VideoDuration
  include ::CarrierWave::Extensions::VideoThumbnailer

  def extension_white_list
    %w(mp4)
  end

  version :thumb do
    process thumbnail: [
      {
        resolution: '320x320',
        preserve_aspect_ratio: :width,
        quality: 1,
        format: "png"
      }
    ]

    def full_filename(for_file)
      png_name for_file, version_name
    end

    # INFO Solution details
    # https://github.com/evrone/carrierwave-video-thumbnailer/issues/6#issuecomment-28664696
    process :set_content_type_png
  end

  def png_name(for_file, version_name)
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.png}
  end

  def set_content_type_png(*args)
    self.file.instance_variable_set(:@content_type, "image/png")
  end
end
