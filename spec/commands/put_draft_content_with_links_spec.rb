require "rails_helper"

RSpec.describe Commands::PutDraftContentWithLinks do
  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  let(:payload) do
    {
      base_path: "/vat-rates",
      publishing_app: "publisher",
    }
  end

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end
end
