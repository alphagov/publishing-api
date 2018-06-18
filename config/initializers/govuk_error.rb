GovukError.configure do |config|
  config.excluded_exceptions << "DownstreamDraftExistsError"
end
