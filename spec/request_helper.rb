require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.include RequestHelpers::Mocks
  c.include RequestHelpers::Actions

  c.extend RequestHelpers::DerivedRepresentations
  c.extend RequestHelpers::DownstreamRequests
  c.extend RequestHelpers::DownstreamTimeouts
  c.extend RequestHelpers::EndpointBehaviour
  c.extend RequestHelpers::EventLogging

  c.include GOVUK::Client::TestHelpers::URLArbiter

  c.before do
    stub_default_url_arbiter_responses
    stub_request(:put, Plek.find('content-store') + "/content#{base_path}")
    stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}")
  end
end
