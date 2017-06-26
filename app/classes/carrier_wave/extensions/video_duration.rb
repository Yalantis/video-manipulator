module CarrierWave::Extensions::VideoDuration
  def self.included(mod)
    mod.send(:process, :save_video_duration)
  end

  def save_video_duration(*args)
    if model.respond_to?("#{mounted_as}_duration")
      duration = FFMPEG::Movie.new(file.file).duration
      model.send("#{mounted_as}_duration=", duration)
    end
  end
end
