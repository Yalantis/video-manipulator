class Video
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification # http://guides.rubyonrails.org/active_job_basics.html#globalid include Mongoid::Document
  field :title, type: String
  field :file, type: String
  field :file_tmp, type: String
  field :file_processing, type: String
  field :file_duration, type: Integer

  mount_uploader :file, ::VideoUploader
  validates_presence_of :file

end
