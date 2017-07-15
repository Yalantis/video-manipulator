class VideoSaverWorker < ::CarrierWave::Workers::StoreAsset
  def perform(*args)
    super(*args)
    run_video_processing_chain_completed_callbacks
  end

  private

  def run_video_processing_chain_completed_callbacks
    record.processing_completed_callback if record.respond_to?(:processing_completed_callback)
  end
end
