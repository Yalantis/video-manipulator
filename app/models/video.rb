class Video
  include Mongoid::Document
  include Mongoid::Timestamps

  # ActiveRecord has this by default.
  # Since it is Mongoid::Document
  # we might need this for data processing at background jobs
  # https://github.com/rails/activemodel-globalid
  # I allows model to be serialized / deserialized by uniqie identifier
  include GlobalID::Identification

  embeds_many :thumbnails

  embeds_many :processing_metadatas

  # Basic fields configuration
  field :title, type: String
  # file_tmp is used for temporary file saving while
  # it processed and stored in the background by carrierwave_backgrounder gem
  field :file_tmp, type: String
  # file_processing attribute is managed by carrierwave_backgrounder when
  # to track is file under processing or not
  field :file_processing, type: Boolean
  # Video duration would be extracted from video metadata
  field :file_duration, type: Integer
  # This would be updated during file processing to track processing progress
  # from 0 to 1
  field :progress, type: Float, default: 0
  # Config option: generate thumbnails for each video second or not
  field :needs_thumbnails, type: Boolean, default: false

  # All user applied effects is stored as array
  field :effects, type: Array, default: []

  # File ffmpeg metadata is stored at hash
  field :metadata, type: Hash, default: {}

  # mount_on is specified here because without it gem
  # would name filename attribute as file_filename
  # In some way it looks logical. But in our case it is strage to have
  # file_filename attribute at database
  mount_uploader :file, ::VideoUploader, mount_on: :file
  process_in_background :file
  store_in_background :file, ::VideoSaverWorker
  validates_presence_of :file

  # The same as above. We do not want to have watermark_image_filename attribute
  mount_uploader :watermark_image, ::ImageUploader, mount_on: :watermark_image

  validates :title, presence: true
  validate :effects_allowed_check

  # This is not good idea to let this thing update database field many times
  # It is made just to test how it works
  def processing_progress(format, format_options, new_progress)
    ProgressCalculator.new(self, format, format_options, new_progress).update!
  end

  def save_metadata(new_metadata)
    set(
      metadata: new_metadata,
      file_duration: new_metadata[:format][:duration]
    )
  end

  def save_thumbnail_files(files_list)
    files_list.each do |file_path|
      ::File.open(file_path, 'r') do |f|
        thumbnails.create!(file: f)
      end
    end
  end

  # before_transcode callback
  # Callback method accepts format and raw options but we do not need them here
  def processing_init_callback(_, _)
    clean_datas
  end

  def processing_completed_callback
    ::ActionCable.server.broadcast(
      'notifications_channel',
      processing_completed: true
    )
  end

  private

  def effects_allowed_check
    effects.each do |effect|
      unless ::VideoUploader::ALLOWED_EFFECTS.include?(effect)
        errors.add(:effects, :not_allowed, effect: effect.humanize)
      end
    end
  end

  def clean_datas
    processing_metadatas.destroy_all
    thumbnails.destroy_all
  end
end
