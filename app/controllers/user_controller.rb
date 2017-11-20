class UserController < ApplicationController
  authorize @user
  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def show
  end

  def create
    @user = User.new
  end

  def update
  end

  def destroy
  end
end
