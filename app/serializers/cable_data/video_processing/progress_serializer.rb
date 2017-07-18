module CableData
  module VideoProcessing
    class ProgressSerializer < ActiveModel::Serializer
      attributes :html, :processing_completed

      def html
        # INFO: This is made for simplicity
        #       But in real application it is better to send
        #       JSON data via action cable only and process
        #       all styling and markup at frontend side
        ApplicationController.renderer.render(
          locals: { video: object },
          partial: 'videos/progress'
        )
      end

      def processing_completed
        false
      end
    end
  end
end
