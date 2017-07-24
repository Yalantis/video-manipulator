class VideoUploader < CarrierWave::Uploader::Base
  # Store and process video in the background
  include ::CarrierWave::Backgrounder::Delay
  # This is custom extension for video metadata extraction
  include ::CarrierWave::Extensions::VideoMetadata
  # Use carrierwave-video gem's methods here
  include ::CarrierWave::Video
  # Use carrierwave-video-thumbnailer gem's methods here
  include ::CarrierWave::Video::Thumbnailer
  # This is custom extension for video thumbnails creation
  include ::CarrierWave::Extensions::VideoMultiThumbnailer

  include ::EncodingConstants

  def extension_whitelist
    %w[mov mp4 3gp mkv webm m4v avi]
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Processing is forced ower original file so when processing is finished,
  # processed file would replace original one.
  # This one line of code enforces this:
  process encode: [:mp4, PROCESSED_DEFAULTS]
  # We just do not need original file. And also this would ensure that
  # Thumbnail would be generated from processed file

  def encode(format, opts = {})
    normalization_step(format, opts)
    apply_effect_steps(format, opts)
    apply_watermark_step(format, opts) if model.watermark_image.path.present?
    read_video_metadata_step(format, opts)
    create_thumbnails_step('jpg', opts) if model.needs_thumbnails?
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
    process :apply_png_content_type
  end

  def png_name(for_file, version_name)
    %(#{version_name}_#{for_file.chomp(File.extname(for_file))}.png)
  end

  def apply_png_content_type(*)
    file.instance_variable_set(:@content_type, 'image/png')
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

  def normalization_step(format, opts)
    encode_video(
      format,
      opts.merge(
        processing_metadata: { step: 'normalize' },
        callbacks: {
          # Clean previous progress data if encoding happens for existing video record
          # Callback method at model
          before_transcode: :processing_init_callback
        }
      )
    )
  end

  def apply_effect_steps(format, opts)
    ordered_effects.each do |effect|
      encode_video(
        format,
        opts.merge(
          processing_metadata: { step: "apply_#{effect}_effect" }
        )
      ) do |_, params|
        params[:custom] = EFFECT_PARAMS[effect.to_sym]
      end
    end
  end

  def apply_watermark_step(format, opts)
    encode_video(
      format,
      opts.merge(processing_metadata: { step: 'apply_watermark' })
    ) do |_, params|
      params[:watermark] ||= {}
      params[:watermark][:path] = model.watermark_image.path
    end
  end

  def read_video_metadata_step(format, opts)
    read_video_metadata(
      format,
      opts.merge(
        save_metadata_method: :save_metadata,
        processing_metadata: { step: 'read_video_metadata' }
      )
    )
  end

  def create_thumbnails_step(format, _opts)
    create_thumbnails_for_video(
      format,
      progress: :processing_progress,
      save_thumbnail_files_method: :save_thumbnail_files,
      resolution: '300x300',
      vframes: model.file_duration, frame_rate: '1', # create thumb for each second of the video
      processing_metadata: { step: 'create_video_thumbnails' }
    )
  end
end
