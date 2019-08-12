require "rails_helper"

RSpec.describe Commands::V2::PostAction do
  describe ".call" do
    let(:document) do
      create(:document,
             content_id: SecureRandom.uuid,
             locale: "en",
             stale_lock_version: 6)
    end
    let(:action) { "AuthBypass" }
    let(:draft) { nil }

    let(:payload) do
      {
        content_id: document.content_id,
        locale: document.locale,
        action: action,
        draft: draft,
      }
    end

    shared_examples "action behaviour" do
      it "creates an action" do
        expect(Action.count).to be 0
        described_class.call(payload)
        expect(Action.count).to be 1
      end

      it "returns a Success object" do
        expect(described_class.call(payload)).to be_a(Commands::Success)
      end

      context "when a non existant content id is requested" do
        before { payload.merge!(content_id: SecureRandom.uuid) }
        include_examples "raises a 404 command error"
      end

      context "when a non existant locale is requested" do
        before { payload.merge!(locale: "fr") }
        include_examples "raises a 404 command error"
      end

      context "when no action is provided" do
        before { payload.merge!(action: nil) }
        it "raises a 422 command error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError) { |e| expect(e.code).to eq(422) }
        end
      end

      context "when a incorrect lock version is provided" do
        before { payload.merge!(previous_version: 5) }
        it "raises a 409 command error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError) { |e| expect(e.code).to eq(409) }
        end
      end
    end

    shared_examples "raises a 404 command error" do
      it "raises a 404 command error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError) { |e| expect(e.code).to eq(404) }
      end
    end

    context "when a draft edition exists" do
      before { create(:draft_edition, document: document) }

      include_examples "action behaviour"
      context "and we specify the action is not for a draft" do
        let(:draft) { false }
        include_examples "raises a 404 command error"
      end
    end

    context "when a published edition exists" do
      before { create(:live_edition, document: document) }

      let(:draft) { false }

      include_examples "action behaviour"

      context "and we specify the action is for a draft" do
        let(:draft) { true }
        include_examples "raises a 404 command error"
      end
    end

    context "when no edition exists" do
      include_examples "raises a 404 command error"
    end
  end
end
