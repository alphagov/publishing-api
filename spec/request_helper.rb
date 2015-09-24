require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"


RSpec.configure do |c|
  c.extend RequestHelpers
  c.include RequestHelpers
  c.include GOVUK::Client::TestHelpers::URLArbiter

  c.before do
    stub_default_url_arbiter_responses
  end
end
