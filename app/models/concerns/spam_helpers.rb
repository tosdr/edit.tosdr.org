module SpamHelpers
  extend self

  def external_uri?(uri)
    app_base_url = ENV['AUTHORITY']
    app_base_url = URI.parse(app_base_url)

    begin
      parsed_uri = URI.parse(uri)
      parsed_uri.host.present? && parsed_uri.host != app_base_url.host
    rescue URI::InvalidURIError
      false
    end
  end

  def contains_external_uri?(user, summary)
    return false if user_is_exempt?(user)

    uris = URI.extract(summary)
    uris.any? { |uri| external_uri?(uri) }
  end

  private

  def user_is_exempt?(user)
    user.curator || user.admin
  end
end
