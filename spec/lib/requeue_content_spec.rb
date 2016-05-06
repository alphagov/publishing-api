require "rails_helper"

RSpec.describe RequeueContent do
  let!(:content_item1) { create(:live_content_item, base_path: '/ci1') }
  let!(:content_item2) { create(:live_content_item, base_path: '/ci2') }
  let!(:content_item3) { create(:live_content_item, base_path: '/ci3') }

  describe "#call" do
    it "by default, it republishes all content items" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message).exactly(3).times
      RequeueContent.new.call
    end

    it "limits the number of items published, if a limit is provided" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .exactly(1)
        .times
        .with(a_hash_including(content_id: content_item1.content_id))
      RequeueContent.new(number_of_items: 1).call
    end
  end
end
