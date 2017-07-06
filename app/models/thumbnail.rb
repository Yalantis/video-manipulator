class Thumbnail
  include Mongoid::Document

  embedded_in :video

  # Here background uploading is not used since this entity would be created in
  # background already
  mount_uploader :file, ::ImageUploader
end
