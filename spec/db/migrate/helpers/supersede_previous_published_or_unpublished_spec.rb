require "rails_helper"
require Rails.root + "db/migrate/helpers/supersede_previous_published_or_unpublished"

RSpec.describe Helpers::SupersedePreviousPublishedOrUnpublished do
  let(:document) { FactoryGirl.create(:document) }

  let!(:unpublished_1) do
    FactoryGirl.create(:superseded_edition,
      document: document,
      user_facing_version: 1,
    )
  end

  let!(:published) do
    FactoryGirl.create(:live_edition,
      document: document,
      user_facing_version: 2,
    )
  end

  let!(:unpublished_2) do
    FactoryGirl.create(:superseded_edition,
      document: document,
      user_facing_version: 3,
    )
  end

  let!(:draft) do
    FactoryGirl.create(:draft_edition,
      document: document,
      user_facing_version: 4,
    )
  end

  before do
    Edition.where(id: [unpublished_1.id, unpublished_2.id]).update_all(state: "unpublished")
  end

  it "supersedes all but the latest published or unpublished item" do
    subject.run

    state_names = [
      unpublished_1,
      published,
      unpublished_2,
      draft
    ].map(&:reload).map(&:state)

    expect(state_names).to eq %w(
      superseded
      superseded
      unpublished
      draft
    )
  end

  it "does not supersede states for content items in other locales" do
    document_fr = FactoryGirl.create(:document,
      content_id: document.content_id,
      locale: "fr",
    )
    french_item = FactoryGirl.create(:live_edition,
      document: document_fr,
      user_facing_version: 1,
    )

    subject.run

    expect(french_item.state).to eq("published")
  end

  it "returns a count of states that have been superseded" do
    expect(subject.run).to eq(2)
  end

  it "is idempotent" do
    subject.run

    expect(subject.run).to be_zero
    expect(subject.run).to be_zero
  end
end
