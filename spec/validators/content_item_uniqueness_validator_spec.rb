require "rails_helper"

RSpec.describe ContentItemUniquenessValidator do
  def assert_valid(record)
    subject.validate(record)
    expect(record.errors).to be_blank, "validation errors: #{record.errors.full_messages}"
  end

  def assert_invalid(record, errors)
    subject.validate(record)
    expect(record.errors[:content_item]).to eq(errors)
  end

  context "for a content item with unique supporting objects" do
    before do
      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_translation,
        :with_location,
        :with_user_facing_version,
      )
    end

    it "has valid supporting objects" do
      assert_valid(State.last)
      assert_valid(Translation.last)
      assert_valid(Location.last)
      assert_valid(UserFacingVersion.last)
    end
  end

  context "for a content item with duplicate supporting objects" do
    before do
      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_translation,
        :with_location,
        :with_user_facing_version,
      )
    end

    let(:content_item) do
      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_translation,
        :with_location,
      )
    end

    it "has an invalid supporting object" do
      user_facing_version = FactoryGirl.build(
        :user_facing_version,
        content_item: content_item,
      )

      expected_error = "conflicts with a duplicate: state=draft, locale=en, base_path=/vat-rates, user_ver=1"
      assert_invalid(user_facing_version, [expected_error])
    end
  end

  context "for a content item with a differentiating supporting object" do
    before do
      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_translation,
        :with_location,
        :with_user_facing_version,
      )

      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_translation,
        :with_location,
        :with_user_facing_version,
        user_facing_version: 2
      )
    end

    it "has valid supporting objects" do
      assert_valid(State.last)
      assert_valid(Translation.last)
      assert_valid(Location.last)
      assert_valid(UserFacingVersion.last)
    end
  end

  context "for a content item with a missing supporting object" do
    before do
      FactoryGirl.create(
        :content_item,
        :with_state,
        :with_location,
        :with_user_facing_version,
      )
    end

    it "has valid supporting objects" do
      assert_valid(State.last)
      assert_valid(Location.last)
      assert_valid(UserFacingVersion.last)
    end
  end
end
