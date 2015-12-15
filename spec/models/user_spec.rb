require 'rails_helper'
require 'gds-sso/lint/user_spec'

RSpec.describe User, type: :model do
  it_behaves_like "a gds-sso user class"
end
