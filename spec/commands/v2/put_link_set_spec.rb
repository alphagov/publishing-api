require "rails_helper"

RSpec.describe Commands::V2::PutLinkSet do
  it "validates the link params" do
    link_params_with_missing_links = {}

    expect {
      described_class.call(link_params_with_missing_links)
    }.to raise_error(CommandError, "Links are required")
  end

  it "updates the LinkSet on disk" do
    link_set = FactoryGirl.create(:link_set, links: {
      organisations: ["some-original-uuid"],
      topics: ["some-topic-uuid"],
    })

    link_params = {
      content_id: link_set.content_id,
      links: {
        organisations: ["some-new-uuid"],
      }
    }

    described_class.call(link_params)

    expect(LinkSet.last.links).to eq(
      organisations: ["some-new-uuid"],
      topics: ["some-topic-uuid"],
    )
  end
end
