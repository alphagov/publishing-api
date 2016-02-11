require "rails_helper"

RSpec.describe Queries::GetPublishIntent do
  let(:base_path) { "/foo" }

  before do
    stub_request(:get, %r{.*content-store.*/publish-intent#{base_path}})
      .to_return(body: { foo: "bar" }.to_json)
  end

  it "returns the body of the response from the content store" do
    result = subject.call(base_path)
    expect(result).to eq(foo: "bar")
  end
end
