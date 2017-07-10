class VideoUploader < CarrierWave::Uploader::Base
  # Store and process video in the background
  include ::CarrierWave::Backgrounder::Delay
  # This is custom extension for video metadata extraction
  include ::CarrierWave::Extensions::VideoMetadata
  # Use carrierwave-video gem's methods here
  include ::CarrierWave::Video
  # Use carrierwave-video-thumbnailer gem's methodds here
  include ::CarrierWave::Video::Thumbnailer
  # This is custom extension for video thumbnails creation
  include ::CarrierWave::Extensions::VideoMultiThumbnailer

  def extension_whitelist
    %w(mov mp4 3gp mkv webm m4v avi)
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  PROCESSED_DEFAULTS = {
    resolution:           '500x400',
    video_codec:          'libx264',
    constant_rate_factor: '30',
    frame_rate:           '25',
    audio_codec:          'aac',
    audio_bitrate:        '64k',
    audio_sample_rate:    '44100',
    audio_channels:       '1',
    strict:               true
  }.freeze

  ADDITIONAL_OPTIONS = {
    progress: :processing_progress
  }

  VIDEO_EFFECTS = {
    sepia:
      %w(-filter_complex colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131 -c:a copy),
    black_and_white: %w(-vf hue=s=0 -c:a copy),
    vertigo: %w(-vf frei0r=vertigo:0.2 -c:a copy),
    vignette: %w(-vf frei0r=vignette -c:a copy),
    sobel: %w(-vf frei0r=sobel -c:a copy),
    pixelizor: %w(-vf frei0r=pixeliz0r -c:a copy),
    invertor: %w(-vf frei0r=invert0r -c:a copy),
    rgbnoise: %w(-vf frei0r=rgbnoise:0.2 -c:a copy),
    distorter: %w(-vf frei0r=distort0r:0.05|0.0000001 -c:a copy),
    iirblur: %w(-vf frei0r=iirblur -c:a copy),
    nervous: %w(-vf frei0r=nervous -c:a copy),
    glow: %w(-vf frei0r=glow:1 -c:a copy),
    reverse: %w(-vf reverse -af areverse),
    slow_down: %w(-filter:v setpts=2.0*PTS -filter:a atempo=0.5),
    speed_up: %w(-filter:v setpts=0.5*PTS -filter:a atempo=2.0)
  }.freeze

  AUDIO_EFFECTS = {
    echo: %w(-map 0 -c:v copy -af aecho=0.8:0.9:1000|500:0.7|0.5),
    tremolo: %w(-map 0 -c:v copy -af tremolo=f=10.0:d=0.7),
    vibrato: %w(-map 0 -c:v copy -af vibrato=f=7.0:d=0.5),
    chorus: %w(-map 0 -c:v copy -af chorus=0.5:0.9:50|60|40:0.4|0.32|0.3:0.25|0.4|0.3:2|2.3|1.3)
  }

  EFFECT_PARAMS = (VIDEO_EFFECTS.merge(AUDIO_EFFECTS)).freeze

  ALLOWED_EFFECTS = EFFECT_PARAMS.keys.map(&:to_s).freeze

  # Processing is forced ower original file so when processing is finished,
  # processed file would replace orignal one. This one line of enforces this:
  process encode: [:mp4, PROCESSED_DEFAULTS.merge(ADDITIONAL_OPTIONS)]
  # We just do not need original file. And also this would ensure that
  # Thumbnail would be generated from processed file

  OBLIGATORY_STEPS = ['normalize', 'read_video_metadata']

  def encode(format, opts={})
    # Normalize file format
    encode_video(format, opts.merge(
      processing_metadata: { step: 'normalize' },
      callbacks: {
        # Clean previous progress data if encoding happens for existing video record
        # Callback method at model
        before_transcode: :processing_init_callback
      }
    ))
    # Apply effects
    ordered_effects.each do |effect|
      encode_video(format, ADDITIONAL_OPTIONS.merge(
        processing_metadata: { step: "apply_#{effect}_effect" }
      )) do |_, params|
        params[:custom] = EFFECT_PARAMS[effect.to_sym]
      end
    end
    # Apply watermark
    if model.watermark_image.path.present?
      encode_video(
        format,
        ADDITIONAL_OPTIONS.merge(processing_metadata: { step: 'apply_watermark' })
      ) do |_, params|
        params[:watermark] ||= {}
        params[:watermark][:path] = model.watermark_image.path
      end
    end

    # Read video metadata
    read_video_metadata(
      format,
      ADDITIONAL_OPTIONS.merge({
        save_metadata_method: :save_metadata,
        processing_metadata: { step: 'read_video_metadata' }
      })
    )

    if model.needs_thumbnails?
      # create thumbnails
      create_thumbnails_for_video(
        'jpg',
        ADDITIONAL_OPTIONS.merge({
          save_thumbnail_files_method: :save_thumbnail_files,
          resolution: '300x300',
          vframes: model.file_duration, frame_rate: '1', # create thumb for each second of the video
          processing_metadata: { step: 'create_video_thumbnails' }
        })
      )
    end
  end

  # Generate one thumbnail from middle (50%) of the file
  # With carrierwave-video-thumbnailer gem
  version :thumb do
    process thumbnail: [
      { format: 'png', quality: 10, size: 200, seek: '50%', logger: Rails.logger }
    ]

    def full_filename(for_file)
      png_name for_file, version_name
    end

    # INFO: This is needed to set proper file content type
    # Solution details
    # https://github.com/evrone/carrierwave-video-thumbnailer/issues/6#issuecomment-28664696
    process :set_content_type_png
  end

  def png_name(for_file, version_name)
    %Q{#{version_name}_#{for_file.chomp(File.extname(for_file))}.png}
  end

  def set_content_type_png(*args)
    self.file.instance_variable_set(:@content_type, 'image/png')
  end

  def audio_effects
    model.effects & AUDIO_EFFECTS.keys.map(&:to_s)
  end

  def video_effects
    model.effects & VIDEO_EFFECTS.keys.map(&:to_s)
  end

  def ordered_effects
    # Audio effects should be applied first
    # since there might be conflict with some video effects
    # (At least with effect that speeds up or slows down video along with audio)
    audio_effects + video_effects
  end
end
