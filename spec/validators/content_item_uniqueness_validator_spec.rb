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
      FactoryGirl.create(:content_item)
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
      FactoryGirl.create(:content_item, user_facing_version: 2)
    end

    let(:content_item) do
      FactoryGirl.create(:content_item, user_facing_version: 1)
    end

    it "has an invalid supporting object" do
      user_facing_version = FactoryGirl.build(
        :user_facing_version,
        content_item: content_item,
        number: 2,
      )

      expected_error = "conflicts with a duplicate: state=draft, locale=en, base_path=/vat-rates, user_version=2"
      assert_invalid(user_facing_version, [expected_error])
    end
  end

  context "for a content item with a differentiating supporting object" do
    before do
      FactoryGirl.create(:content_item)

      FactoryGirl.create(:content_item, user_facing_version: 2)
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
      content_item = FactoryGirl.create(:content_item)
      Translation.find_by!(content_item: content_item).destroy
    end

    it "has valid supporting objects" do
      assert_valid(State.last)
      assert_valid(Location.last)
      assert_valid(UserFacingVersion.last)
    end
  end

  context "when a duplicate content item exists in a withdrawn state" do
    let!(:content_item) do
      FactoryGirl.create(:content_item, state: "withdrawn")
    end

    it "allows duplicates and does not raise an error" do
      expect {
        FactoryGirl.create(:content_item, state: "withdrawn")
      }.not_to raise_error

      expect(ContentItem.count).to eq(2)
    end
  end
end
