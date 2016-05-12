require "rails_helper"

RSpec.describe DataHygiene::AccessLimitsCleaner, :cleanup do
  let!(:unrelated_access_limit) { create(:access_limit) }
  let(:draft_content_item) { create(:draft_content_item) }
  let(:another_draft_content_item) { create(:draft_content_item) }
  let!(:dupe_access_limit) { create(:access_limit, content_item: draft_content_item) }
  let!(:another_dupe_access_limit) { create(:access_limit, content_item: draft_content_item) }
  let!(:access_limit) { create(:access_limit, content_item: draft_content_item) }

  let(:live_content_item) { create(:live_content_item) }
  let!(:published_access_limit) { create(:access_limit, content_item: live_content_item) }

  let(:log) { double(:log) }

  before do
    allow(log).to receive(:puts)
  end

  it "cleans up duplicate AccessLimits" do
    expect {
      described_class.cleanup(log: log)
    }.to change(AccessLimit, :count).by(-3)
    # verify the latest record was retained
    expect(AccessLimit.all).to match_array([access_limit, unrelated_access_limit])
  end

  it "cleans up AccessLimits associated with published content" do
    expect {
      described_class.cleanup(log: log)
    }.to change(AccessLimit, :count).by(-3)
    # verify the live content access limit was destroyed
    expect {
      AccessLimit.find(published_access_limit.id)
    }.to raise_error ActiveRecord::RecordNotFound
  end
end
