require "gds_api/test_helpers/content_store"

RSpec.describe DataHygiene::DocumentStatusChecker do
  include GdsApi::TestHelpers::ContentStore

  let(:base_path) { "/base-path" }

  describe "content-store status" do
    subject { described_class.new(document).content_store? }

    context "with a published live edition" do
      let(:edition) { create(:live_edition, base_path:) }
      let(:document) { edition.document }

      context "and there is no content item" do
        before { stub_content_store_does_not_have_item(base_path) }
        it { is_expected.to be false }
      end

      context "and there is an old content item" do
        let(:content_item) do
          content_item_for_base_path(base_path).merge(
            "updated_at" => (edition.published_at - 1).iso8601,
          )
        end
        before { stub_content_store_has_item(base_path, content_item) }
        it { is_expected.to be false }
      end

      context "and there is a recent content item" do
        let(:content_item) do
          content_item_for_base_path(base_path).merge(
            "updated_at" => (edition.published_at + 1).iso8601,
          )
        end
        before { stub_content_store_has_item(base_path, content_item) }
        it { is_expected.to be true }
      end
    end
  end
end
