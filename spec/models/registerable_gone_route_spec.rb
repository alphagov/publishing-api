require 'rails_helper'

RSpec.describe RegisterableGoneRoute, :type => :model do
  let(:factory_name) { :registerable_gone_route }
  it_behaves_like 'a valid registerable route'
end
