class VideoUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay
  include ::CarrierWave::Extensions::VideoDuration
  include ::CarrierWave::Extensions::VideoThumbnailer
  include ::CarrierWave::Video

  def extension_whitelist
    %w(mov mp4 3gp mkv webm m4v avi)
  end

  version :processed do
    encode_video :mp4,
     resolution:           '500x400',
     video_codec:          'libx264',
     reference_frames:     '4',
     constant_rate_factor: '30',
     frame_rate:           '25',
     x264_vprofile:        'baseline',
     x264_vprofile_level:  '3',
     audio_codec:          'aac',
     audio_bitrate:        '64k',
     audio_sample_rate:    '44100',
     audio_channels:       '1',
     strict:               true
  end

  version :thumb do
    process thumbnail: [
      {
        resolution: '200x200',
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
