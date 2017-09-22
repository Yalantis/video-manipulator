module CableData
  module VideoProcessing
    class CompletedSerializer < BaseSerializer
      attributes :html, :processing_completed

      def html
        # INFO: This is made for simplicity
        #       But in real application it is better to send
        #       JSON data via action cable only and process
        #       all styling and markup at frontend side
        ApplicationController.renderer.render(
          locals: { video: object },
          partial: 'videos/info'
        )
      end

      def processing_completed
        true
      end
    end
  end
end
