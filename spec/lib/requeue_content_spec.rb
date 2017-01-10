require "rails_helper"

RSpec.describe RequeueContent do
  before do
    Edition.destroy_all
  end

  let!(:edition1) { FactoryGirl.create(:live_edition, base_path: '/ci1') }
  let!(:edition2) { FactoryGirl.create(:live_edition, base_path: '/ci2') }
  let!(:edition3) { FactoryGirl.create(:live_edition, base_path: '/ci3') }

  describe "#call" do
    it "by default, it republishes all content items" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message).exactly(3).times
      RequeueContent.new.call
    end

    it "limits the number of items published, if a limit is provided" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .exactly(1)
        .times
        .with(a_hash_including(:content_id))
      RequeueContent.new(number_of_items: 1).call
    end
  end
end
