require "rails_helper"

RSpec.describe Queries::ContentItemUniqueness do
  let(:base_path) { "/unique-content-item" }
  let(:user_facing_version) { "2" }
  let(:locale) { "en" }
  let(:state) { "draft" }

  describe "#unique_fields_for_content_item" do
    context "content item exists" do
      it "returns a hash of the unique fields" do
        content_item = FactoryGirl.create(
          :content_item,
          base_path: base_path,
          locale: locale,
          state: state,
          user_facing_version: user_facing_version,
        )

        result = Queries::ContentItemUniqueness.unique_fields_for_content_item(content_item)
        expect(result).to eq(
          content_id: content_item.content_id,
          base_path: base_path,
          locale: locale,
          state: state,
          user_facing_version: user_facing_version,
        )
      end
    end

    context "content item does not exist" do
      it "returns nil" do
        content_item = FactoryGirl.build(:content_item)
        result = Queries::ContentItemUniqueness.unique_fields_for_content_item(content_item)
        expect(result).to be_nil
      end
    end
  end

  describe "#first_non_unique_item" do
    before do
      @existing_content_item = FactoryGirl.create(
        :content_item,
        base_path: base_path,
        locale: locale,
        state: state,
        user_facing_version: user_facing_version,
      )
      @different_content_item = FactoryGirl.create(:content_item)
    end

    context "content item conflicts" do
      it "returns a hash of the conflict" do
        result = Queries::ContentItemUniqueness.first_non_unique_item(
          @different_content_item,
          base_path: base_path,
          locale: locale,
          state: state,
          user_facing_version: user_facing_version,
        )
        expect(result).to eq(
          content_id: @existing_content_item.content_id,
          base_path: base_path,
          locale: locale,
          state: state,
          user_facing_version: user_facing_version,
        )
      end
    end

    context "content item does not conflict" do
      context "different base_path" do
        it "returns nil" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: "/new-base-path",
            locale: locale,
            state: state,
            user_facing_version: user_facing_version,
          )

          expect(result).to be_nil
        end
      end
      context "different locale" do
        it "returns nil" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: base_path,
            locale: "fr",
            state: state,
            user_facing_version: user_facing_version,
          )

          expect(result).to be_nil
        end
      end

      context "different state" do
        it "returns nil" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: base_path,
            locale: locale,
            state: "published",
            user_facing_version: user_facing_version,
          )

          expect(result).to be_nil
        end
      end

      context "different user facing version" do
        it "returns nil" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: base_path,
            locale: locale,
            state: state,
            user_facing_version: "4",
          )

          expect(result).to be_nil
        end
      end
    end

    context "content item has an empty base_path" do
      before do
        @existing_content_item = FactoryGirl.create(
          :content_item,
          base_path: nil,
          document_type: "contact",
          locale: locale,
          state: state,
          user_facing_version: user_facing_version,
        )
        @different_content_item = FactoryGirl.create(
          :content_item,
          base_path: nil,
          document_type: "contact",
        )
      end

      context "does not conflict" do
        it "returns nil" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: nil,
            locale: "fr",
            state: state,
            user_facing_version: user_facing_version,
          )

          expect(result).to be_nil
        end
      end

      context "does conflict" do
        it "returns a hash of the conflict" do
          result = Queries::ContentItemUniqueness.first_non_unique_item(
            @different_content_item,
            base_path: nil,
            locale: locale,
            state: state,
            user_facing_version: user_facing_version,
          )

          expect(result).to eq(
            content_id: @existing_content_item.content_id,
            base_path: nil,
            locale: locale,
            state: state,
            user_facing_version: user_facing_version,
          )
        end
      end
    end
  end
end
