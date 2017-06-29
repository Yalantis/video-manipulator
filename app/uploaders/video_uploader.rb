class VideoUploader < CarrierWave::Uploader::Base
  include ::CarrierWave::Backgrounder::Delay
  include ::CarrierWave::Extensions::VideoDuration
  include ::CarrierWave::Video
  include ::CarrierWave::Video::Thumbnailer

  def extension_whitelist
    %w(mov mp4 3gp mkv webm m4v avi)
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  PROCESSED_DEFAULTS = {
    resolution:           '500x400',
    video_codec:          'libx264',
    reference_frames:     '4',
    constant_rate_factor: '30',
    frame_rate:           '25',
    x264_vprofile_level:  '3',
    audio_codec:          'aac',
    audio_bitrate:        '64k',
    audio_sample_rate:    '44100',
    audio_channels:       '1',
    strict:               true
  }.freeze

  ADDITIONAL_OPTIONS = {
    progress: :processing_progress
  }

  EFFECT_PARAMS = {
    no_effect: [],
    sepia:
      %w(-filter_complex colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131 -c:a copy),
    black_and_white: %w(-vf hue=s=0 -c:a copy),
    vertigo: %w(-vf frei0r=vertigo:0.2),
    vignette: %w(-vf frei0r=vignette),
    sobel: %w(-vf frei0r=sobel),
    pixelizor: %w(-vf frei0r=pixeliz0r),
    invertor: %w(-vf frei0r=invert0r),
    rgbnoise: %w(-vf frei0r=rgbnoise:0.2),
    reverse: %w(-vf reverse -af areverse),
    slow_down: %w(-filter:v setpts=2.0*PTS -filter:a atempo=0.5),
    speed_up: %w(-filter:v setpts=0.5*PTS -filter:a atempo=2.0),
    echo: %w(-map 0 -c:v copy -af aecho=0.8:0.9:1000:0.3)
  }.freeze

  ALLOWED_EFFECTS = EFFECT_PARAMS.keys.map(&:to_s).freeze

  process encode: [:mp4, PROCESSED_DEFAULTS.merge(ADDITIONAL_OPTIONS)]

  def encode(format, opts={})
    # Normalize file format
    encode_video(format, opts)
    # Apply effects
    if model.effect != 'no_effect'
      encode_video(format, ADDITIONAL_OPTIONS) do |_, params|
        params[:custom] = EFFECT_PARAMS[model.effect.to_sym]
      end
    end
    # Apply watermark
    if model.watermark_image.path.present?
      encode_video(format, ADDITIONAL_OPTIONS) do |_, params|
        params[:watermark] ||= {}
        params[:watermark][:path] = model.watermark_image.path
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

    def full_filename(for_file)
      %(#{version_name}_#{for_file.chomp(File.extname(for_file))}.jpg)
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
