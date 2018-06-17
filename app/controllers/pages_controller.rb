class PagesController < ApplicationController
  def home
    @versions = Version.all
  end
end
