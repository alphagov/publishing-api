GDS::SSO.config do |config|
  # FIXME: This app should be switched to be Rails api_only. Once this is done
  # this setting will be superfluous
  config.api_only = true
end
