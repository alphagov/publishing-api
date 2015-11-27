require "rails_helper"

RSpec.describe Commands::V2::PutLinkSet do
  let(:content_id) { "a5f715f9-a0b3-4186-823d-d31f6af4b060" }

  let(:old_uuid) { SecureRandom.uuid }
  let(:new_uuid) { SecureRandom.uuid }
  let(:topic_uuid) { SecureRandom.uuid }
  let(:first_set) {
    {
      content_id: content_id,
      links: {
        organisations: [old_uuid],
        topics: [topic_uuid],
      }
    }
  }
  let(:second_set) {
    {
      content_id: content_id,
      links: {
        organisations: [new_uuid],
      }
    }
  }

  before do
    described_class.call(first_set)
  end

  it "validates the link params" do
    link_params_with_missing_links = {}

    expect {
      described_class.call(link_params_with_missing_links)
    }.to raise_error(CommandError, "Links are required")
  end

  it "updates the LinkSet on disk" do
    described_class.call(second_set)
    stored_content_ids = Link.all.map(&:target_content_id)

    expect(stored_content_ids).to match_array([new_uuid, topic_uuid])
  end
end
