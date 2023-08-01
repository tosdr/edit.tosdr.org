# frozen_string_literal: true

# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @versions = Version.order('created_at DESC').limit(50) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
    if current_user&.curator
      docbot_user = User.find_by_username('docbot')
      @pending_points = Point.where(status: %w[pending approved-not-found])
                             .where.not(user_id: [current_user.id, docbot_user.id])
                             .includes(:service)
                             .includes(:case)
                             .includes(:user)
                             .order(updated_at: :asc)
                             .limit(10)
                             .offset(rand(100))

      @docbot_points = Point.includes(:case)
                            .includes(:service)
                            .includes(:user)
                            .where(user_id: docbot_user.id)
                            .where(status: 'pending')
                            .limit(10)
                            .offset(rand(100))
                          # .order('ml_score DESC')
    end

    if current_user
      @draft_points = Point.where(status: 'draft')
                           .where(user_id: current_user.id)
                           .includes(:service)
                           .includes(:case)
                           .includes(:user)
                           .limit(10)

      @change_request_points = Point.where(status: 'changes-requested')
                                    .where(user_id: current_user.id)
                                    .includes(:service)
                                    .includes(:case)
                                    .includes(:user)
                                    .limit(10)
    end

    # Only load example services for users who are not curators and don't have existing points to deal with.
    if (!@pending_points && (!@draft_points || @draft_points.count == 0) && (!@change_request_points || @change_request_points.count == 0))
      @services = Service.includes(points: [:case])
                         .sample(3)
    end
  end
end
