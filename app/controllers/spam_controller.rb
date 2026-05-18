# frozen_string_literal: true

# app/controllers/spam_controller.rb
class SpamController < ApplicationController
  include Pundit::Authorization
  include ApplicationHelper

  SPAMMABLE_TYPES = {
    'PointComment' => PointComment,
    'CaseComment' => CaseComment,
    'DocumentComment' => DocumentComment,
    'ServiceComment' => ServiceComment,
    'TopicComment' => TopicComment
  }.freeze

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def flag_as_spam
    authorize Spam

    flagger_is_permitted = current_user && (current_user.admin? || current_user.curator?) ? true : false
    spammable = find_spammable!
    id = spammable.user_id
    spam_owner = User.find(id)

    if spam_owner.admin || spam_owner.curator || spam_owner.bot
      flash[:alert] = 'You are not authorized to perform this action on admins, curators or bots.'
      redirect_to(request.referrer || root_path)
      return
    end

    spam = Spam.new(spammable_type: params[:spammable_type], spammable_id: params[:spammable_id].to_i, flagged_by_admin_or_curator: flagger_is_permitted)
    spam.save

    report_spam(spammable.summary, 'spam')
    flash[:notice] = 'Comment has been marked as Spam.'
    redirect_to(request.referrer || root_path)
  end

  private

  def find_spammable!
    spammable_class = SPAMMABLE_TYPES[params[:spammable_type]]
    raise ActiveRecord::RecordNotFound, 'Unsupported spam target' unless spammable_class

    spammable_class.find(params[:spammable_id])
  end

  def spam_params
    params.require(:spam).permit(:spammable_type, :spammable_id)
  end
end
