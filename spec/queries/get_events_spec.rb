RSpec.describe Queries::GetEvents do
  let(:edition) { create(:live_edition) }
  let(:document) { edition.document }

  let!(:patch_link_set_events) { create_list(:event, 2, content_id: document.content_id, action: "PatchLinkSet") }
  let!(:put_content_events) { create_list(:event, 3, content_id: document.content_id, action: "PutContent") }
  let!(:publish_events) { create_list(:event, 1, content_id: document.content_id, action: "Publish") }
  let!(:host_content_update_events) { create_list(:event, 2, content_id: document.content_id, action: "HostContentUpdateJob") }
  let!(:other_events) { create_list(:event, 4) }

  let(:all_events) do
    [
      patch_link_set_events,
      put_content_events,
      publish_events,
      host_content_update_events,
    ].flatten
  end

  it "returns all events" do
    result = described_class.call(content_id: document.content_id)

    expect(result).to match_array(all_events)
  end

  it "allows filtering by action" do
    result = described_class.call(content_id: document.content_id, action: "HostContentUpdateJob")

    expect(result).to match_array(host_content_update_events)
  end

  context "filtering by date" do
    let(:start_date) { Time.zone.now }

    it "returns no events when events have not been created since the start date" do
      result = described_class.call(content_id: document.content_id, from: start_date)
      expect(result).to match_array([])
    end

    it "returns all events created since the start date" do
      create_list(:event, 2, content_id: document.content_id, created_at: start_date - 2.hours)
      result = described_class.call(content_id: document.content_id, from: start_date - 1.hour)

      expect(result).to match_array(all_events)
    end

    it "returns all events create between the start and end dates" do
      create_list(:event, 2, content_id: document.content_id, created_at: start_date - 2.hours)
      create_list(:event, 2, content_id: document.content_id, created_at: start_date + 2.hours)

      result = described_class.call(content_id: document.content_id, from: start_date - 1.hour, to: start_date + 1.hour)

      expect(result).to match_array(all_events)
    end

    it "filters by action" do
      create_list(:event, 2, content_id: document.content_id, action: "PatchLinkSet", created_at: start_date + 1.hour)
      publish_actions = create_list(:event, 2, content_id: document.content_id, action: "Publish", created_at: start_date + 1.hour)

      result = described_class.call(content_id: document.content_id, from: start_date, action: "Publish")

      expect(result).to match_array(publish_actions)
    end
  end
end
