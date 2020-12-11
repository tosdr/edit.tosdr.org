class PagesController < ApplicationController
  def home
    @versions = Version.order("created_at DESC").limit(50) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
    if current_user&.curator then
      @pending_points = Point
                  .where(status: ['pending', 'approved-not-found'])
                  .where.not(user_id: current_user.id)
                  .includes(:service)
                  .includes(:case)
                  .includes(:user)
                  .order(updated_at: :asc)
                  .limit(10)
                  .offset(rand(100))
    end

    if current_user then
      @draft_points = Point
                  .where(status: 'draft')
                  .where(user_id: current_user.id)
                  .includes(:service)
                  .includes(:case)
                  .includes(:user)
                  .limit(10)

      @change_request_points = Point
                  .where(status: 'changes-requested')
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
