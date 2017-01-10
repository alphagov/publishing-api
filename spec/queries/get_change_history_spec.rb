require "rails_helper"

RSpec.describe Queries::GetChangeHistory do
  let(:app1) { "baba-ganoush" }
  let(:app2) { "fattoush" }

  let(:details) do
    { change_history: [
      { public_timestamp: 1.day.ago.to_s, note: "note 1" },
      { public_timestamp: 2.days.ago.to_s, note: "note 2" },
    ] }
  end

  subject { described_class }

  let!(:item1) do
    FactoryGirl.create(:edition, details: details, publishing_app: app1)
  end
  let!(:item2) do
    FactoryGirl.create(:edition, details: details, publishing_app: app1)
  end
  let!(:item3) do
    FactoryGirl.create(:edition, details: details, publishing_app: app2)
  end
  let!(:item4) do
    FactoryGirl.create(:edition, details: {}, publishing_app: app2)
  end

  it "gets application-specific history data" do
    ids = subject.(app1).map { |res| res[:edition_id] }
    expect(ids).to match_array [item1.id, item1.id, item2.id, item2.id]
  end

  it "returns array of hashes with note, timestamp and item id" do
    result = subject.(app1)
    expected = details[:change_history].first.merge(edition_id: item1.id)
    expect(result).to include expected
  end
end
