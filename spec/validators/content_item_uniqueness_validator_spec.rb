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

  let(:base_path) { "/vat-rates" }

  context "for a content item with unique supporting objects" do
    before do
      FactoryGirl.create(:content_item,
        base_path: base_path,
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
    let!(:existing_item) do
      FactoryGirl.create(:content_item,
        user_facing_version: 2,
        base_path: base_path,
      )
    end

    let(:content_item) do
      FactoryGirl.create(:content_item,
        user_facing_version: 1,
        base_path: base_path,
      )
    end

    it "has an invalid supporting object" do
      user_facing_version = FactoryGirl.build(:user_facing_version,
        content_item: content_item,
        number: 2,
      )

      expected_error = "conflicts with a duplicate: state=draft, locale=en, base_path=/vat-rates, user_version=2, "\
                       "content_id=#{existing_item.content_id}"
      assert_invalid(user_facing_version, [expected_error])
    end
  end

  context "for a content item with a differentiating supporting object" do
    before do
      FactoryGirl.create(:content_item,
        base_path: base_path,
      )
      FactoryGirl.create(:content_item,
        user_facing_version: 2,
        base_path: base_path,
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
      content_item = FactoryGirl.create(:content_item, base_path: base_path)
      Translation.find_by!(content_item: content_item).destroy
    end

    it "has valid supporting objects" do
      assert_valid(State.last)
      assert_valid(Location.last)
      assert_valid(UserFacingVersion.last)
    end
  end

  context "for a content item that doesn't require base_path" do
    before do
      @content_item = FactoryGirl.create(
        :content_item,
        base_path: nil,
        document_type: "contact",
        user_facing_version: 2
      )
    end

    it "doesn't attempt to find similar items" do
      expect(Queries::ContentItemUniqueness).not_to receive(:first_non_unique_item)

      subject.validate(State.find_by(content_item: @content_item))
      expect(@content_item.errors).to be_empty
    end
  end
end
