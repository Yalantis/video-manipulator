class VideosController < ApplicationController
  before_action :set_video, only: %i[show edit update destroy]

  # GET /videos
  def index
    @videos = Video.order_by(created_at: :desc).page(params[:page])
  end

  # GET /videos/1
  # def show
  # end

  # GET /videos/new
  def new
    @video = Video.new
  end

  # GET /videos/1/edit
  # def edit
  # end

  # POST /videos
  def create
    @video = Video.new(video_params)

    respond_to do |format|
      if @video.save
        format.html { redirect_to @video, notice: 'Video was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /videos/1
  def update
    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to @video, notice: 'Video was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /videos/1
  def destroy
    @video.destroy
    respond_to do |format|
      format.html { redirect_to videos_url, notice: 'Video was successfully destroyed.' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_video
    @video = Video.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def video_params
    params.require(:video).permit(:title, :file, :watermark_image, :needs_thumbnails, effects: [])
  end
end
