GDS::SSO.config do |config|
  config.user_model = "User"
  config.oauth_id = ENV["OAUTH_ID"] || "abcdefg"
  config.oauth_secret = ENV["OAUTH_SECRET"] || "secret"
  config.oauth_root_url = Plek.find("signon")
  config.cache = Rails.cache
  # FIXME: This app should be switched to be Rails api_only. Once this is done
  # this setting will be superfluous
  config.api_only = true
end
