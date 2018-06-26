class PagesController < ApplicationController
  def home
    @services = Service.includes(points: [:case]).with_points_featured.sample(3)
    @versions = Version.order("created_at DESC").limit(50) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
    @versions.each do |version|
      version.whodunnit = User.find(version.whodunnit).username || '(User ' + version.whodunnit + ')'
    end
  end
end
