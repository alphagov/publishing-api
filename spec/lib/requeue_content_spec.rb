require "rails_helper"

RSpec.describe RequeueContent do
  before do
    FactoryGirl.create(:live_edition, base_path: '/ci1')
    FactoryGirl.create(:live_edition, base_path: '/ci2')
    FactoryGirl.create(:live_edition, base_path: '/ci3')
  end

  describe "#call" do
    it "by default, it republishes all editions" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message).exactly(3).times
      RequeueContent.new.call
    end

    it "limits the number of items published, if a limit is provided" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .exactly(1)
        .times
        .with(a_hash_including(:content_id), event_type: "links")
      RequeueContent.new(number_of_items: 1).call
    end
  end
end
