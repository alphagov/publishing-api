require "rails_helper"

RSpec.describe Queries::GetLinked do
  let(:content_id) { SecureRandom.uuid }
  let(:target_content_id) { SecureRandom.uuid }

  describe "#call" do
    context "item with given content id does not exist" do
      it "raises not found error" do
        non_existing_content_id = "39599c18-c7b8-4fd3-ae2d-a3c3cb310dd5"

        expect {
          Queries::GetLinked.new(
            content_id: non_existing_content_id,
            link_type: "organisations",
            fields: [],
          ).call
        }.to raise_error(CommandError)
      end
    end

    context "when content item exists "do
      before do
        create(:live_content_item, :with_draft, content_id: target_content_id, base_path: "/pay-now")
      end

      context "but no content item links to it" do
        it "returns an empty array" do
          expect(
            Queries::GetLinked.new(
              content_id: target_content_id,
              link_type: "organisations",
              fields: [],
            ).call
          ).to eq([ ])
        end
      end

      context "but requested fields are invalid" do
        it "raises an error" do
          expect {
            Queries::GetLinked.new(
              content_id: target_content_id,
              link_type: "organisations",
              fields: ['not_existing'],
            ).call
          }.to raise_error(CommandError)
        end
      end

      context "an item has a link of given type to it" do
        before do
          create(:live_content_item, :with_draft, content_id: content_id, title: "VAT and VATy things")
          link_set = create(:link_set, content_id: content_id)
          create(:link, link_set: link_set, link_type: "organisations", target_content_id: target_content_id)

          content_item = create(:live_content_item, :with_draft, base_path: '/vatty', content_id: SecureRandom.uuid, title: "Another VATTY thing")
          link_set = create(:link_set, content_id: content_item.content_id)
          create(:link, link_set: link_set, link_type: "organisations", target_content_id: target_content_id)

          create(:link, link_set: link_set, link_type: "related_links", target_content_id: SecureRandom.uuid)
        end

        context "custom fields have been requested" do
          it "returns array of hashes, with requested fields" do
            expect(
              Queries::GetLinked.new(
                content_id: target_content_id,
                link_type: "organisations",
                fields: ["title"])
              .call
            ).to match_array([
              {
                "title" => "Another VATTY thing",
                "publication_state" => "live",
              },
              {
                "title" => "VAT and VATy things",
                "publication_state" => "live",
              }
            ])
          end
        end

        context "no fields requested" do
          it "returns array of empty hashes" do
            expect(
              Queries::GetLinked.new(
                content_id: target_content_id,
                link_type: "organisations",
                fields: [])
              .call
            ).to eq([ {}, {} ])
          end
        end
      end
    end
  end
end
