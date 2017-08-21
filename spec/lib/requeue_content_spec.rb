require "rails_helper"

RSpec.describe RequeueContent do
  before do
    FactoryGirl.create(:live_edition, base_path: '/ci1')
    FactoryGirl.create(:live_edition, base_path: '/ci2')
    FactoryGirl.create(:live_edition, base_path: '/ci3')
    FactoryGirl.create(:gone_live_edition, base_path: '/ci4')
    FactoryGirl.create(:redirect_live_edition, base_path: '/ci5')
    FactoryGirl.create(:draft_edition, base_path: '/ci5')
  end

  describe "#call" do
    it "it republishes all live editions" do
      scope = Edition
        .with_document
        .with_unpublishing

      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message).exactly(5).times

      RequeueContent.new(scope).call
    end
  end
end
