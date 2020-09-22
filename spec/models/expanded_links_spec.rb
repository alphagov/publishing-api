require "rails_helper"

RSpec.describe ExpandedLinks do
  describe ".locked_update" do
    let(:content_id) { SecureRandom.uuid }
    let(:locale) { "en" }
    let(:with_drafts) { true }
    let(:payload_version) { 2 }
    let(:expanded_links) do
      {
        organisations: [
          { content_id: SecureRandom.uuid },
        ],
      }
    end

    let(:attributes) do
      {
        content_id: content_id,
        locale: locale,
        with_drafts: with_drafts,
        payload_version: payload_version,
        expanded_links: expanded_links,
      }
    end

    subject(:run_method) { described_class.locked_update(**attributes) }

    context "when there isn't an instance" do
      it "creates one" do
        expect { run_method }.to change(ExpandedLinks, :count).by(1)
      end
    end

    context "when there is an instance and the payload version of the update is greater" do
      let!(:expanded_links_instance) do
        create(
          :expanded_links,
          content_id: content_id,
          locale: locale,
          with_drafts: with_drafts,
          payload_version: 1,
          expanded_links: {},
        )
      end

      it "updates the links" do
        run_method
        expanded_links_instance.reload
        expect(expanded_links_instance.expanded_links).to match(expanded_links.as_json)
        expect(expanded_links_instance.payload_version).to match(payload_version)
      end
    end

    context "when there is an instance and the payload version of the update is lower" do
      let!(:expanded_links_instance) do
        create(
          :expanded_links,
          content_id: content_id,
          locale: locale,
          with_drafts: with_drafts,
          payload_version: 5,
          expanded_links: {},
        )
      end

      it "doesn't update" do
        run_method
        expanded_links_instance.reload
        expect(expanded_links_instance.expanded_links).to match({})
        expect(expanded_links_instance.payload_version).to match(5)
      end
    end
  end
end
