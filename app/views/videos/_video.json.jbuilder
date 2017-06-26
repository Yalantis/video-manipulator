json.extract! video, :id, :title, :file, :file_processing, :file_duration, :created_at, :updated_at
json.url video_url(video, format: :json)
