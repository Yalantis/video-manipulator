class VideoUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay
  include ::CarrierWave::Extensions::VideoDuration
  include ::CarrierWave::Video
  include ::CarrierWave::Video::Thumbnailer

  def extension_whitelist
    %w(mov mp4 3gp mkv webm m4v avi)
  end

  PROCESSED_DEFAULTS = {
    resolution:           '500x400',
    # video_codec:          'libx264',
    # reference_frames:     '4',
    # constant_rate_factor: '30',
    # frame_rate:           '25',
    # x264_vprofile_level:  '3',
    # audio_codec:          'aac',
    # audio_bitrate:        '64k',
    # audio_sample_rate:    '44100',
    # audio_channels:       '1',
    # strict:               true,
    progress: :processing_progress
  }.freeze

  SEPIA_EFFECT_PARAMS =
    %w(-filter_complex colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131 -c:a copy).freeze
  BLACK_AND_WHITE_EFFECT_PARAMS =
    %w(-vf hue=s=0 -c:a copy).freeze

  process encode: [:mp4, PROCESSED_DEFAULTS]

  def encode(format, opts={})
    encode_video(format, opts) do |_, params|
      params[:custom] ||= []
      case model.effect
      when 'sepia'
        params[:custom] += SEPIA_EFFECT_PARAMS
      when 'black_and_white'
        params[:custom] += BLACK_AND_WHITE_EFFECT_PARAMS
      when 'no_effect'
        # Watermark is not compatilble with above filters
        if model.watermark_image.path.present?
          params[:watermark] ||= {}
          params[:watermark][:path] = model.watermark_image.path
        end
      end
    end
  end

  version :thumb do
    process thumbnail: [
      { format: 'png', quality: 10, size: 200, seek: '50%', logger: Rails.logger }
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
