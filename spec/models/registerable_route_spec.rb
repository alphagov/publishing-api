require 'rails_helper'

RSpec.describe RegisterableRoute, :type => :model do
  let(:factory_name) { :registerable_route }
  it_behaves_like 'a valid registerable route'
end
