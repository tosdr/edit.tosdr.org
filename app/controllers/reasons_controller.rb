class ReasonsController < ApplicationController
  before_action :set_point, only: [:new, :create]
  before_action :set_admin
  def new
    @reason = Reason.new
  end

  def create
    # must update status of the point and make sure it is saved so that the user can see it and respond
    @reason = Reason.new(reason_params)
    @reason.point = @point
    @point.update(point_params)
    @reason.status = @point.status

    @reason.user = @point.user
    if @reason.save
      flash[:notice] = "Status saved!"
      redirect_to point_path(@point)
    else
      render :new
    end
  end

  private

  def set_admin
    unless current_user.curator?
      redirect_to root_path
      flash[:alert] = "You must be a curator"
    end
  end

  def set_point
    @point = Point.find(params[:point_id])
  end

  def reason_params
    params.require(:reason).permit(:content)
  end
  def point_params
    params.require(:point).permit(:status)
  end
end
