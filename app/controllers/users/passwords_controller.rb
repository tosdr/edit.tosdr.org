# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  include RequiresAltcha

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    unless altcha_valid?
      self.resource = resource_class.new(password_reset_params)
      return render_altcha_failure!(:new, resource: resource)
    end

    super
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  def password_reset_params
    params.fetch(resource_name, {}).permit(:email)
  end
end
