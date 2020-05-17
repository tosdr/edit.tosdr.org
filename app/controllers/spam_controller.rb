class SpamController < ApplicationController
  include Pundit

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def flag_as_spam
    authorize Spam
    
    flagger_is_permitted = current_user && (current_user.admin? || current_user.curator?) ? true : false
    spam = Spam.new(spammable_type: params[:spammable_type], spammable_id: params[:spammable_id].to_i, flagged_by_admin_or_curator: flagger_is_permitted)
    spam.save
    redirect_to(request.referrer || root_path)
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def spam_params
    params.require(:spam).permit(:spammable_type, :spammable_id)
  end
end
