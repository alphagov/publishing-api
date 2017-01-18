require "rails_helper"

RSpec.describe Queries::GetLinked do
  let(:content_id) { SecureRandom.uuid }
  let(:target_content_id) { SecureRandom.uuid }
  let(:another_target_content_id) { SecureRandom.uuid }

  describe "#call" do
    context "item with given content id does not exist" do
      it "raises not found error" do
        non_existing_content_id = "39599c18-c7b8-4fd3-ae2d-a3c3cb310dd5"

        expect {
          Queries::GetLinked.new(
            content_id: non_existing_content_id,
            link_type: "organisations",
            fields: ["title"],
          ).call
        }.to raise_error(CommandError)
      end
    end

    context "no fields requested" do
      it "raises an error" do
        expect {
          Queries::GetLinked.new(
            content_id: target_content_id,
            link_type: "organisations",
            fields: [],
          ).call
        }.to raise_error(CommandError)
      end
    end

    context "when a content item with no draft exists" do
      before do
        FactoryGirl.create(:live_content_item,
          document: FactoryGirl.create(:document, content_id: content_id),
          base_path: "/vat-rules-2020",
          title: "VAT rules 2020",
        )

        FactoryGirl.create(:live_content_item,
          document: FactoryGirl.create(:document, content_id: target_content_id),
          base_path: "/vat-org",
        )
      end

      it "returns no results when no content is linked to it" do
        expect(
          Queries::GetLinked.new(
            content_id: content_id,
            link_type: "organisations",
            fields: ["title"],
          ).call
        ).to eq([])
      end

      context "where another content item is linked to it" do
        before do
          link_set = FactoryGirl.create(:link_set, content_id: content_id)
          FactoryGirl.create(:link, link_set: link_set, target_content_id: target_content_id)
        end

        it "should return the linked item" do
          expect(Queries::GetLinked.new(
            content_id: target_content_id,
            link_type: "organisations",
            fields: ["title"],
          ).call).to match_array([hash_including("title" => "VAT rules 2020")])
        end
      end
    end

    context "when a content item with draft exists "do
      before do
        FactoryGirl.create(:live_content_item,
          :with_draft,
          document: FactoryGirl.create(:document, content_id: target_content_id),
          base_path: "/pay-now"
        )
      end

      context "but no content item links to it" do
        it "returns an empty array" do
          expect(
            Queries::GetLinked.new(
              content_id: target_content_id,
              link_type: "organisations",
              fields: ["title"],
            ).call
          ).to eq([])
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

      context "content items link to the wanted content item" do
        before do
          FactoryGirl.create(:live_content_item,
            document: FactoryGirl.create(:document, content_id: content_id),
            title: "VAT and VATy things",
            base_path: "/vat-rates",
          )
          FactoryGirl.create(:link_set,
            content_id: content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: target_content_id
              )
            ]
          )

          content_item = FactoryGirl.create(:live_content_item,
            base_path: '/vatty',
            title: "Another VATTY thing"
          )
          FactoryGirl.create(:link_set,
            content_id: content_item.document.content_id,
            links: [
              FactoryGirl.create(:link,
                link_type: "organisations",
                target_content_id: target_content_id
              ),
              FactoryGirl.create(:link,
                link_type: "related_links",
                target_content_id: target_content_id
              )
            ]
          )
        end

        context "custom fields have been requested" do
          it "returns array of hashes, with requested fields" do
            expect(
              Queries::GetLinked.new(
                content_id: target_content_id,
                link_type: "organisations",
                fields: %w(title base_path locale publication_state))
              .call
            ).to match_array([
              {
                "title" => "Another VATTY thing",
                "publication_state" => "published",
                "base_path" => "/vatty",
                "locale" => "en",
              },
              {
                "title" => "VAT and VATy things",
                "publication_state" => "published",
                "base_path" => "/vat-rates",
                "locale" => "en",
              }
            ])
          end
        end

        context "when a link_type is specified" do
          it "filters the links by the specified link_type" do
            expect(
              Queries::GetLinked.new(
                content_id: target_content_id,
                link_type: "related_links",
                fields: %w(base_path))
              .call
            ).to match_array([
              { "base_path" => "/vatty" }
            ])
          end
        end
      end

      context "draft items linking to the wanted draft item" do
        before do
          FactoryGirl.create(:live_content_item,
            :with_draft,
            document: FactoryGirl.create(:document, content_id: another_target_content_id),
            base_path: "/send-now"
          )

          FactoryGirl.create(:draft_content_item,
            document: FactoryGirl.create(:document, content_id: content_id),
            title: "HMRC documents"
          )

          FactoryGirl.create(:link_set,
            content_id: content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: another_target_content_id
              ),
            ]
          )

          content_item = FactoryGirl.create(:draft_content_item,
            base_path: '/other-hmrc-document',
            title: "Another HMRC document"
          )

          FactoryGirl.create(
            :link_set,
            content_id: content_item.document.content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: another_target_content_id
              ),
              FactoryGirl.create(
                :link,
                link_type: "related_links",
                target_content_id: SecureRandom.uuid
              )
            ]
          )
        end

        it "returns array of hashes, with requested fields" do
          expect(
            Queries::GetLinked.new(
              content_id: another_target_content_id,
              link_type: "organisations",
              fields: %w(title publication_state))
            .call
          ).to match_array([
            {
              "title" => "HMRC documents",
              "publication_state" => "draft",
            },
            {
              "title" => "Another HMRC document",
              "publication_state" => "draft",
            }
          ])
        end
      end
    end
  end
end
