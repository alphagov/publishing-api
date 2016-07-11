require "rails_helper"
require Rails.root + "db/migrate/helpers/supersede_previous_published_or_unpublished"

RSpec.describe Helpers::SupersedePreviousPublishedOrUnpublished do
  let(:content_id) { SecureRandom.uuid }

  let!(:unpublished_1) do
    FactoryGirl.create(
      :unpublished_content_item,
      content_id: content_id,
      user_facing_version: 1,
    )
  end

  let!(:published) do
    FactoryGirl.create(
      :live_content_item,
      content_id: content_id,
      user_facing_version: 2,
    )
  end

  let!(:unpublished_2) do
    FactoryGirl.create(
      :unpublished_content_item,
      content_id: content_id,
      user_facing_version: 3,
    )
  end

  let!(:draft) do
    FactoryGirl.create(
      :draft_content_item,
      content_id: content_id,
      user_facing_version: 4,
    )
  end

  it "supersedes all but the latest published or unpublished item" do
    subject.run

    state_names = [
      unpublished_1,
      published,
      unpublished_2,
      draft
    ].map { |c| State.find_by!(content_item: c).name }

    expect(state_names).to eq %w(
      superseded
      superseded
      unpublished
      draft
    )
  end

  it "does not supersede states for content items in other locales" do
    french_item = FactoryGirl.create(
      :live_content_item,
      content_id: content_id,
      user_facing_version: 1,
      locale: "fr",
    )

    subject.run

    state_name = State.find_by!(content_item: french_item).name
    expect(state_name).to eq("published")
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
