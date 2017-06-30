class Thumbnail
  include Mongoid::Document

  embedded_in :video

  mount_uploader :file, ::ImageUploader
end
