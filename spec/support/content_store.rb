RSpec.configure do |c|
  c.before :each, :type => :request do
    stub_request(:put, Plek.find('content-store') + "/content#{base_path}")
    stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}")
    stub_request(:delete, Plek.find('draft-content-store') + "/content#{base_path}")
  end
end
