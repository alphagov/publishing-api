require "rails_helper"
require "gds_api/test_helpers/content_store"
require "gds_api/test_helpers/router"

RSpec.describe DataHygiene::DocumentStatusChecker do
  include GdsApi::TestHelpers::ContentStore
  include GdsApi::TestHelpers::Router

  let(:base_path) { "/base-path" }

  describe "content-store status" do
    subject { described_class.new(document).content_store? }

    context "with a published live edition" do
      let(:edition) { create(:live_edition, base_path: base_path) }
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

  describe "router status" do
    subject { described_class.new(document).router? }

    around do |example|
      ClimateControl.modify ROUTER_API_BEARER_TOKEN: "token" do
        example.run
      end
    end

    context "with a published live edition" do
      let(:edition) { create(:live_edition, base_path: base_path) }
      let(:document) { edition.document }

      context "and there is no content item" do
        before { stub_router_doesnt_have_route(base_path) }
        it { is_expected.to be false }
      end

      context "and there is a content item" do
        before { stub_router_has_backend_route(base_path, backend_id: backend_id) }

        context "with the same backend_id" do
          let(:backend_id) { edition.rendering_app }
          it { is_expected.to be true }
        end

        context "with a different backend_id" do
          let(:backend_id) { "nothing" }
          it { is_expected.to be false }
        end
      end
    end
  end
end
