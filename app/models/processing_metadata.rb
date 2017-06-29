class ProcessingMetadata
  include Mongoid::Document

  embedded_in :video

  field :step, type: String
  field :format, type: String
  field :progress, type: Float, default: 0
end
