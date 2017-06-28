class Video
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification

  field :title, type: String
  field :file_tmp, type: String
  field :file_processing, type: Boolean
  field :file_duration, type: Integer
  field :progress, type: Float, default: 0

  field :effect, type: String

  mount_uploader :file, ::VideoUploader
  process_in_background :file
  store_in_background :file
  validates_presence_of :file

  mount_uploader :watermark_image, ::ImageUploader

  validates :title, presence: true
  ALLOWED_EFFECTS = %w(no_effect sepia black_and_white vertigo vignette sobel pixelizor invertor rgbnoise).freeze
  validates :effect, inclusion: { in: ALLOWED_EFFECTS }

  # This is not good idea to let this thing update database field many times
  # It is made just to test how it works
  def processing_progress(format, format_options, new_progress)
    # Update this value only each 10th percent
    diff = (new_progress.to_f - self.progress.to_f)
    if diff >= 0.1 || (new_progress.to_i == 1)
      # Had to use atomic set operation here since normal update
      # has been setting file_processing to false while processing still was not finished
      self.set(progress: new_progress.to_f)
    end
  end

end
