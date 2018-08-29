class PagesController < ApplicationController
  def home
    @versions = Version.order("created_at DESC").limit(50) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
    if current_user&.curator
      @points = Point
                  .where(status: 'pending')
                  .where.not(user_id: current_user.id)
                  .includes(:service)
                  .includes(:case)
                  .includes(:user)
                  .limit(20)
    else
      @services = Service.includes(points: [:case])
                    .with_points_featured.sample(3)
    end
  end
end
