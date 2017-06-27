class Video
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification # http://guides.rubyonrails.org/active_job_basics.html#globalid include Mongoid::Document
  field :title, type: String
  field :file, type: String
  field :file_tmp, type: String
  field :file_processing, type: Boolean
  field :file_duration, type: Integer
  field :progress, type: Float

  field :apply_sepia_effect, type: Boolean

  mount_uploader :file, ::VideoUploader
  process_in_background :file
  store_in_background :file
  validates_presence_of :file

  validates :title, presence: true

  # This is not good idea to let this thing update database field many times
  # It is made just to test how it works
  def processing_progress(format, format_options, progress)
    self.update_attribute(:progress, progress.to_f)
  end

end
