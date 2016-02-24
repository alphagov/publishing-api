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

    context "when content item with draft exists "do
      before do
        FactoryGirl.create(
          :live_content_item,
          :with_draft,
          content_id: target_content_id,
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

      context "content items link to the wanted content item" do
        before do
          FactoryGirl.create(
            :live_content_item,
            content_id: content_id,
            title: "VAT and VATy things"
          )
          FactoryGirl.create(
            :link_set,
            content_id: content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: target_content_id
              )
            ]
          )

          content_item = FactoryGirl.create(
            :live_content_item,
            base_path: '/vatty',
            content_id: SecureRandom.uuid,
            title: "Another VATTY thing"
          )
          FactoryGirl.create(
            :link_set,
            content_id: content_item.content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: target_content_id
              ),
              FactoryGirl.create(
                :link,
                link_type: "related_links",
                target_content_id: SecureRandom.uuid
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
                fields: ["title", "base_path", "locale"])
              .call
            ).to match_array([
              {
                "title" => "Another VATTY thing",
                "publication_state" => "live",
                "base_path" => "/vatty",
                "locale" => "en",
              },
              {
                "title" => "VAT and VATy things",
                "publication_state" => "live",
                "base_path" => "/vat-rates",
                "locale" => "en",
              }
            ])
          end
        end
      end

      context "draft items linking to the wanted draft item" do
        before do
          FactoryGirl.create(
            :live_content_item,
            :with_draft,
            content_id: another_target_content_id,
            base_path: "/send-now"
          )

          FactoryGirl.create(
            :draft_content_item,
            content_id: content_id,
            title: "HMRC documents"
          )

          link_set = FactoryGirl.create(
            :link_set,
            content_id: content_id,
            links: [
              FactoryGirl.create(
                :link,
                link_type: "organisations",
                target_content_id: another_target_content_id
              ),
            ]
          )

          content_item = FactoryGirl.create(
            :draft_content_item,
            base_path: '/other-hmrc-document',
            content_id: SecureRandom.uuid,
            title: "Another HMRC document"
          )
          FactoryGirl.create(
            :link_set,
            content_id: content_item.content_id,
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
              fields: ["title"])
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
