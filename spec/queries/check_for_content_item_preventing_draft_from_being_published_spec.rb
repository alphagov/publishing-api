require "rails_helper"

RSpec.describe Queries::CheckForContentItemPreventingDraftFromBeingPublished do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let(:document_type) { "guide" }

  describe ".call" do
    subject { described_class.call(content_id, base_path, document_type) }

    shared_examples "check succeeds" do
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "with a single content item" do
      before do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      include_examples "check succeeds"
    end

    context "with two content items of different locales" do
      before do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path + ".en",
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path + ".es",
          document_type: document_type,
          user_facing_version: 1,
          locale: "es",
        )
      end

      include_examples "check succeeds"
    end

    context "with a unpublished item, of type \"substitute\", and a draft at the same base path" do
      before do
        FactoryGirl.create(:unpublished_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: document_type,
          unpublishing_type: "substitute",
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      include_examples "check succeeds"
    end

    context "with a published item, with a substitutable document_type, and a draft at the same base path" do
      before do
        FactoryGirl.create(:live_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: "unpublishing",
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      include_examples "check succeeds"
    end

    context "with a draft with a substitutable document_type, and a published item at the same base path" do
      let(:document_type) { "unpublishing" }

      before do
        FactoryGirl.create(:live_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: "guide",
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      include_examples "check succeeds"
    end

    context "with a unpublished item, and a draft at the same base path" do
      before do
        @blocking_content_item = FactoryGirl.create(:gone_unpublished_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      it "fails, returning the id of the content item" do
        expect(subject).to eq(@blocking_content_item.id)
      end
    end

    context "with a published item, and a draft at the same base path" do
      before do
        @blocking_content_item = FactoryGirl.create(:live_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )

        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      it "fails, returning the id of the content item" do
        expect(subject).to eq(@blocking_content_item.id)
      end
    end

    context "with no base_path" do
      let(:base_path) { nil }

      let!(:blocking_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      let!(:blocking_content_item_2) do
        FactoryGirl.create(:live_content_item,
          content_id: SecureRandom.uuid,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      let!(:content) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
          base_path: base_path,
          document_type: document_type,
          user_facing_version: 1,
          locale: "en",
        )
      end

      it "doesn't raise any errors" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
