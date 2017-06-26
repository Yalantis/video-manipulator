class ProcessVideoJob < ActiveJob::Base
  queue_as :carrierwave

  include ::CarrierWave::Workers::ProcessAssetMixin
  # ... or include ::CarrierWave::Workers::StoreAssetMixin

  after_perform do
    # TODO: Notify user via Action Cable
  end

  # Sometimes job gets performed before the file is uploaded and ready.
  # You can define how to handle that case by overriding `when_not_ready` method
  # (by default it does nothing)
  def when_not_ready
    retry_job
  end
end
