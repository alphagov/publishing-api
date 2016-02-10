# TURN THESE INTO REQUEST SPECS

require "rails_helper"

RSpec.describe "Reallocating base paths of content items" do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let(:command) { Commands::V2::PutContent }

  before do
    stub_request(:put, %r{.*draft-content-store.*/content/.*})
  end

  let(:regular_payload) do
    FactoryGirl.build(:draft_content_item,
      content_id: content_id,
    ).as_json.deep_symbolize_keys.merge(base_path: base_path)
  end

  let(:substitute_payload) do
    FactoryGirl.build(:redirect_draft_content_item,
      content_id: content_id,
    ).as_json.deep_symbolize_keys.merge(base_path: base_path)
  end

  context "when a base path is occupied by a 'regular' content item" do
    before do
      FactoryGirl.create(
        :draft_content_item,
        :with_location,
        :with_translation,
        :with_semantic_version,
        base_path: base_path
      )
    end

    it "cannot be replaced by another 'regular' content item" do
      expect {
        command.call(regular_payload)
      }.to raise_error(CommandError) { |error|
        expect(error.code).to eq(422)
      }
    end
  end

  describe "publishing a draft which has a different content_id to the published content item on the same base_path" do
    let(:command) { Commands::V2::Publish }
    let(:draft_content_id) { SecureRandom.uuid }
    let(:live_content_id) { SecureRandom.uuid }
    let(:payload) { { update_type: "major", content_id: draft_content_id } }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when both content items are 'regular' content items" do
      before do
        draft = FactoryGirl.create(
          :draft_content_item,
          :with_location,
          :with_translation,
          :with_semantic_version,
          content_id: draft_content_id,
          base_path: base_path
        )

        live = FactoryGirl.create(
          :live_content_item,
          :with_location,
          :with_translation,
          :with_semantic_version,
          content_id: live_content_id,
          base_path: base_path
        )

        FactoryGirl.create(:version, target: live, number: 5)
        FactoryGirl.create(:version, target: draft, number: 3)
      end

      it "raises an error" do
        expect {
          command.call(payload)
        }.to raise_error(CommandError) { |error|
          expect(error.code).to eq(422)
        }
      end
    end

    describe "/v1 put_content_with_links" do
      let(:command) { Commands::PutContentWithLinks }

      context "when a base path is occupied by a not-yet-published regular content item" do
        before do
          FactoryGirl.create(
            :draft_content_item,
            :with_location,
            :with_translation,
            :with_semantic_version,
            base_path: base_path
          )
        end

        it "cannot be replaced by another regular content item" do
          expect {
            command.call(regular_payload)
          }.to raise_error(CommandError) { |error|
            expect(error.code).to eq(422)
          }
        end
      end

      context "when a base path is occupied by a published regular content item" do
        before do
          FactoryGirl.create(
            :live_content_item,
            :with_draft,
            :with_location,
            :with_semantic_version,
            base_path: base_path
          )
        end

        it "cannot be replaced by another regular content item" do
          expect {
            command.call(regular_payload)
          }.to raise_error(CommandError) { |error|
            expect(error.code).to eq(422)
          }
        end
      end
    end
  end
end
