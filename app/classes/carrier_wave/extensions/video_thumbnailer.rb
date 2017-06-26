module CarrierWave::Extensions::VideoThumbnailer
  extend ActiveSupport::Concern

  module ClassMethods
    def thumbnail options = {}
      process thumbnail: options
    end
  end

  def thumbnail opts = {}
    cache_stored_file! if !cached?
    @options = opts
    prepare_params_by(opts)

    tmp_path = File.join(File.dirname(current_path), "tmpfile.#{@format}")
    movie = FFMPEG::Movie.new(current_path)
    # Details here
    # https://github.com/streamio/streamio-ffmpeg#taking-screenshots
    movie.screenshot(tmp_path, @options_hash_one, @options_hash_two)
    File.rename tmp_path, current_path
  end

  private
  def prepare_params_by(opts)
    @format = @options.delete(:format) || 'jpg'
    @options_hash_one = {}

    [:seek_time, :resolution].each do |param|
      @options_hash_one[param] = opts.delete(param)
    end

    @options_hash_two = {}
    [:preserve_aspect_ratio, :quality].each do |param|
      @options_hash_two[param] = opts.delete(param)
    end
  end
end
