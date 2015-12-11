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
      base_path: base_path
    ).as_json.deep_symbolize_keys
  end

  let(:substitute_payload) do
    FactoryGirl.build(:redirect_draft_content_item,
      content_id: content_id,
      base_path: base_path
    ).as_json.deep_symbolize_keys
  end

  context "when a base path is occupied by a not-yet-published regular content item" do
    before do
      FactoryGirl.create(:draft_content_item, base_path: base_path)
    end

    it "cannot be replaced by another regular content item" do
      expect {
        command.call(regular_payload)
      }.to raise_error(CommandRetryableError)
    end

    it "can be replaced by a 'substitute' content item" do
      command.call(substitute_payload)

      stored_content_item = DraftContentItem.find_by(base_path: base_path)
      expect(stored_content_item.content_id).to eq(content_id)
    end
  end

  context "when a base path is occupied by a published regular content item" do
    before do
      FactoryGirl.create(:live_content_item, :with_draft, base_path: base_path)
    end

    it "cannot be replaced by another regular content item" do
      expect {
        command.call(regular_payload)
      }.to raise_error(CommandRetryableError)
    end

    it "can be replaced by a 'substitute' content item" do
      command.call(substitute_payload)

      stored_draft_item = DraftContentItem.find_by(base_path: base_path)
      stored_live_item = LiveContentItem.find_by(base_path: base_path)

      expect(stored_draft_item.content_id).to eq(content_id)
      expect(stored_live_item.content_id).to_not eq(content_id)
    end
  end

  context "when a base path is occupied by a not-yet-published 'substitute' content item" do
    before do
      FactoryGirl.create(:redirect_draft_content_item, base_path: base_path)
    end

    it "can be replaced by a regular content item" do
      command.call(regular_payload)

      stored_content_item = DraftContentItem.find_by(base_path: base_path)
      expect(stored_content_item.content_id).to eq(content_id)
    end

    it "can be replaced by another 'substitute' content item" do
      command.call(substitute_payload)

      stored_content_item = DraftContentItem.find_by(base_path: base_path)
      expect(stored_content_item.content_id).to eq(content_id)
    end
  end

  context "when a base path is occupied by a published 'substitute' content item" do
    before do
      FactoryGirl.create(:redirect_live_content_item, :with_draft, base_path: base_path)
    end

    it "can be replaced by a regular content item" do
      command.call(regular_payload)

      stored_draft_item = DraftContentItem.find_by(base_path: base_path)
      stored_live_item = LiveContentItem.find_by(base_path: base_path)

      expect(stored_draft_item.content_id).to eq(content_id)
      expect(stored_live_item.content_id).to_not eq(content_id)
    end

    it "can be replaced by another 'substitute' content item" do
      command.call(substitute_payload)

      stored_draft_item = DraftContentItem.find_by(base_path: base_path)
      stored_live_item = LiveContentItem.find_by(base_path: base_path)

      expect(stored_draft_item.content_id).to eq(content_id)
      expect(stored_live_item.content_id).to_not eq(content_id)
    end
  end

  describe "publishing a reallocated base_path" do
    let(:command) { Commands::V2::Publish }
    let(:draft_content_id) { SecureRandom.uuid }
    let(:live_content_id) { SecureRandom.uuid }
    let(:payload) { { update_type: "major", content_id: draft_content_id } }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when both content items are regular content items" do
      before do
        draft = FactoryGirl.create(:draft_content_item, content_id: draft_content_id, base_path: base_path)
        live = FactoryGirl.create(:live_content_item, content_id: live_content_id, base_path: base_path)

        FactoryGirl.create(:version, target: live, number: 5)
        FactoryGirl.create(:version, target: draft, number: 3)
      end

      it "raises an error" do
        expect {
          command.call(payload)
        }.to raise_error(CommandRetryableError)
      end
    end

    context "when the draft content item is regular and the live is substitute" do
      before do
        draft = FactoryGirl.create(:draft_content_item, content_id: draft_content_id, base_path: base_path)
        live = FactoryGirl.create(:redirect_live_content_item, content_id: live_content_id, base_path: base_path)

        FactoryGirl.create(:version, target: live, number: 5)
        FactoryGirl.create(:version, target: draft, number: 3)
      end

      it "replaces the live content item with the draft" do
        expect {
          command.call(payload)
        }.to_not change(LiveContentItem, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        expect(live_item.content_id).to eq(draft_content_id)
      end

      it "replaces the version with a new version" do
        expect {
          command.call(payload)
        }.to_not change(Version, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        live_version = Version.find_by!(target: live_item)
        expect(live_version.number).to eq(3)
      end
    end

    context "when the draft content item is substitute and the live is regular" do
      before do
        draft = FactoryGirl.create(:redirect_draft_content_item, content_id: draft_content_id, base_path: base_path)
        live = FactoryGirl.create(:live_content_item, content_id: live_content_id, base_path: base_path)

        FactoryGirl.create(:version, target: live, number: 5)
        FactoryGirl.create(:version, target: draft, number: 3)
      end

      it "replaces the live content item with the draft" do
        expect {
          command.call(payload)
        }.to_not change(LiveContentItem, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        expect(live_item.content_id).to eq(draft_content_id)
      end

      it "replaces the version with a new version" do
        expect {
          command.call(payload)
        }.to_not change(Version, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        live_version = Version.find_by!(target: live_item)
        expect(live_version.number).to eq(3)
      end
    end

    context "when both content items are substitute content items" do
      before do
        draft = FactoryGirl.create(:redirect_draft_content_item, content_id: draft_content_id, base_path: base_path)
        live = FactoryGirl.create(:redirect_live_content_item, content_id: live_content_id, base_path: base_path)

        FactoryGirl.create(:version, target: live, number: 5)
        FactoryGirl.create(:version, target: draft, number: 3)
      end

      it "replaces the live content item with the draft" do
        expect {
          command.call(payload)
        }.to_not change(LiveContentItem, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        expect(live_item.content_id).to eq(draft_content_id)
      end

      it "replaces the version with a new version" do
        expect {
          command.call(payload)
        }.to_not change(Version, :count)

        live_item = LiveContentItem.find_by(base_path: base_path)
        live_version = Version.find_by!(target: live_item)
        expect(live_version.number).to eq(3)
      end
    end

    describe "/v1 put_content_with_links" do
      let(:command) { Commands::PutContentWithLinks }

      context "when a base path is occupied by a not-yet-published regular content item" do
        before do
          FactoryGirl.create(:draft_content_item, base_path: base_path)
        end

        it "cannot be replaced by another regular content item" do
          expect {
            command.call(regular_payload)
          }.to raise_error(CommandRetryableError)
        end

        it "can be replaced by a 'substitute' content item" do
          command.call(substitute_payload)

          stored_content_item = DraftContentItem.find_by(base_path: base_path)
          expect(stored_content_item.content_id).to eq(content_id)
        end
      end

      context "when a base path is occupied by a published regular content item" do
        before do
          FactoryGirl.create(:live_content_item, :with_draft, base_path: base_path)
        end

        it "cannot be replaced by another regular content item" do
          expect {
            command.call(regular_payload)
          }.to raise_error(CommandRetryableError)
        end

        it "replaces both the draft and live content items" do
          command.call(substitute_payload)

          stored_draft_item = DraftContentItem.find_by(base_path: base_path)
          stored_live_item = LiveContentItem.find_by(base_path: base_path)

          expect(stored_draft_item.content_id).to eq(content_id)
          expect(stored_live_item.content_id).to eq(content_id)
        end
      end

      context "when a base path is occupied by a not-yet-published 'substitute' content item" do
        before do
          FactoryGirl.create(:redirect_draft_content_item, base_path: base_path)
        end

        it "can be replaced by a regular content item" do
          command.call(regular_payload)

          stored_content_item = DraftContentItem.find_by(base_path: base_path)
          expect(stored_content_item.content_id).to eq(content_id)
        end

        it "can be replaced by another 'substitute' content item" do
          command.call(substitute_payload)

          stored_content_item = DraftContentItem.find_by(base_path: base_path)
          expect(stored_content_item.content_id).to eq(content_id)
        end
      end

      context "when a base path is occupied by a published 'substitute' content item" do
        before do
          FactoryGirl.create(:redirect_live_content_item, :with_draft, base_path: base_path)
        end

        it "replaces both the draft and live content items" do
          command.call(regular_payload)

          stored_draft_item = DraftContentItem.find_by(base_path: base_path)
          stored_live_item = LiveContentItem.find_by(base_path: base_path)

          expect(stored_draft_item.content_id).to eq(content_id)
          expect(stored_live_item.content_id).to eq(content_id)
        end

        it "can be replaced by another 'substitute' content item" do
          command.call(substitute_payload)

          stored_draft_item = DraftContentItem.find_by(base_path: base_path)
          stored_live_item = LiveContentItem.find_by(base_path: base_path)

          expect(stored_draft_item.content_id).to eq(content_id)
          expect(stored_live_item.content_id).to eq(content_id)
        end
      end
    end
  end

  describe "moving an item to a new path" do
    let(:new_base_path) { "/new-vat-rates" }
    let(:existing) {
      FactoryGirl.create(:draft_content_item,
        content_id: content_id,
        base_path: base_path
      )
    }
    let(:payload) {
      existing.as_json.deep_symbolize_keys.tap do |payload|
        payload[:base_path] = new_base_path
        payload[:routes][0][:path] = new_base_path
      end
    }

    context "when the item has not been published" do
      it "creates a draft at the new path and a deletes the draft at the old path" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
          .with(base_path)
        command.call(payload)

        expect(DraftContentItem.find_by(content_id: content_id).base_path).to eq(new_base_path)
      end
    end

    context "when the item has previously been published" do
      before do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
          draft_content_item: existing,
        )
      end
      it "put_content creates a draft at the new path and a draft redirect from the old path" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(base_path: new_base_path, content_item: hash_including(format: existing.format))
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(base_path: base_path, content_item: hash_including(format: "redirect"))
        command.call(payload)

        expect(DraftContentItem.find_by(content_id: content_id).base_path).to eq(new_base_path)
        redirect = DraftContentItem.find_by(base_path: base_path)
        expect(redirect.format).to eq("redirect")
        expect(redirect.redirects[0][:destination]).to eq(new_base_path)
      end

      it "publishing creates the live item at the new path and a live redirect from the old path" do
        FactoryGirl.create(:version, target: existing, number: 1)
        existing.update(base_path: new_base_path, routes: payload[:routes])
        redirect = FactoryGirl.create(:redirect_draft_content_item, base_path: base_path, destination: new_base_path)
        FactoryGirl.create(:version, target: redirect, number: 1)
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(base_path: new_base_path, content_item: hash_including(format: existing.format))
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(base_path: base_path, content_item: hash_including(format: "redirect"))
        Commands::V2::Publish.call(content_id: content_id, update_type: "major")

        expect(LiveContentItem.find_by(content_id: content_id).base_path).to eq(new_base_path)
        redirect = LiveContentItem.find_by(base_path: base_path)
        expect(redirect.format).to eq("redirect")
        expect(redirect.redirects[0][:destination]).to eq(new_base_path)
      end
    end
  end
end
