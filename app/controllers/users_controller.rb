class UsersController < Devise::RegistrationsController
  def destroy
    @user.points.update_all user_id: 4 # change to anonymous account id
    if @user.destroy
      @user.destroy
      flash[:notice] = "Your data has been deleted and your contribution have been assigned to an anonymous account"
    else
      flash[:alert] = "Woops! The deletion of your accound as failed, please contact the team!"
    end
  end
end
