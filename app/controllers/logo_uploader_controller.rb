# frozen_string_literal: true

# app/controllers/logo_uploader_controller.rb
class LogoUploaderController < CarrierWave::Uploader::Base
  storage :fog

  def initialize(service_id)
    @service_id = service_id
  end

  def extension_allowlist
    %w[png]
  end

  def content_type_allowlist
    [/image\//]
  end

  def store_dir
    '/'
  end

  def filename
    "#{@service_id}.#{file.extension}" if original_filename.present?
  end
end
