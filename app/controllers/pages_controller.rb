# frozen_string_literal: true

# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
    if current_user&.curator
      docbot_user = User.docbot_user
      ids = []
      ids << current_user.id
      ids << docbot_user.id if docbot_user.present?
      @pending_points = Point.pending(ids)
      @docbot_points = docbot_user.present? ? Point.docbot : []
    end

    if current_user
      @draft_points = Point.draft(current_user.id)
      @change_request_points = Point.changes_requested(current_user.id)
    end

    # Only load example services for users who are not curators and don't have existing points to deal with.
    no_drafts = !@draft_points || @draft_points.count.zero?
    no_change_requests = !@change_request_points || @change_request_points.count.zero?
    @services = Service.includes(points: [:case]).order(Arel.sql('RANDOM()')).limit(3)
  end
end
