require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.include GOVUK::Client::TestHelpers::URLArbiter, :type => :request

  c.before :each, :type => :request do
    stub_default_url_arbiter_responses
  end
end
