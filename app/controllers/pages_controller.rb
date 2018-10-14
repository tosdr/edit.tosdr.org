class PagesController < ApplicationController
  def home
    @versions = Version.order("created_at DESC").limit(50) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')

    # Only load example services for users who are not curators and don't have existing points to deal with.
    # Checks to see that current user does NOT have ANY points and checks to see that user is NOT a curator

    if current_user.nil? || (!current_user.points.any? && !current_user.curator?)
      @user_no_points = true
      @services = Service.includes(points: [:case])
                    .sample(3)
    end
  end
end
