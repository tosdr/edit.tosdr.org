class PagesController < ApplicationController
  def home
    @services = Service.includes(:points).with_points_featured.sample(3)
    @versions = Version.order("created_at DESC").limit(5) # .joins('INNER JOIN users ON "whodunnit"= cast(users."id" as text)')
  end
end
