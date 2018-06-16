class PagesController < ApplicationController
  def home
    if params[:query]
      @services = Service.includes(:points).where('name ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
    else
      @services = Service.includes(:points).with_points
    end
  end
end
