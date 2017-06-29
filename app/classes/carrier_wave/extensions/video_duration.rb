module CarrierWave::Extensions::VideoDuration
  def self.included(mod)
    # In order to get processed file duration we have to do this
    # after file has been stored
    mod.send(:after, :store, :save_video_duration)
  end

  def save_video_duration(*args)
    if model.respond_to?("#{mounted_as}_duration")
      duration = FFMPEG::Movie.new(file.file).duration
      model.update_attribute("#{mounted_as}_duration", duration)
    end
  end
end
