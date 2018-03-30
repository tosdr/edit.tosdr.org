class PagesController < ApplicationController
  def home
    if params[:query]
      @services = Service.where('name ILIKE ? or grade ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
    else
      @services = Service.with_points
    end
  end
end
