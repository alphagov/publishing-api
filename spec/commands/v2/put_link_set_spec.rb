require "rails_helper"

RSpec.describe Commands::V2::PutLinkSet do
  let(:content_id) { "a5f715f9-a0b3-4186-823d-d31f6af4b060" }
  let(:link_params) {
    {
      content_id: content_id,
      links: {
        organisations: ["some-new-uuid"],
      }
    }
  }

  before do
    @existing_link_set = FactoryGirl.create(:link_set,
      content_id: content_id,
      links: {
        organisations: ["some-original-uuid"],
        topics: ["some-topic-uuid"],
      }
    )
  end

  it "validates the link params" do
    link_params_with_missing_links = {}

    expect {
      described_class.call(link_params_with_missing_links)
    }.to raise_error(CommandError, "Links are required")
  end

  it "updates the LinkSet on disk" do
    described_class.call(link_params)

    expect(@existing_link_set.reload.links).to eq(
      organisations: ["some-new-uuid"],
      topics: ["some-topic-uuid"],
    )
  end
end
