require "rails_helper"

RSpec.describe Commands::DeletePublishIntent do
  before do
    stub_request(:delete, %r{.*content-store.*/publish-intent/.*})
  end

  let(:payload) do
    {
      base_path: "/vat-rates",
    }
  end

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end
end
