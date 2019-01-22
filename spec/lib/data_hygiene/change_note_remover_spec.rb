require 'rails_helper'

RSpec.describe DataHygiene::ChangeNoteRemover do
  let(:document) { create(:document) }
  let!(:superseded_edition) { create(:superseded_edition, document: document, change_note: "First change note.", update_type: "major") }
  let!(:live_edition) { create(:live_edition, document: document, change_note: "Second change note.", update_type: "major", user_facing_version: 2) }

  let(:query) { nil }

  def call_change_note_remover
    described_class.call(document.content_id, document.locale, query, dry_run: dry_run)
  end

  subject(:deleted_change_note) { call_change_note_remover }

  context "during a dry run" do
    let(:dry_run) { true }

    context "the query matches a change note" do
      let(:query) { "second" }

      it "doesn't delete the change note" do
        expect(superseded_edition.reload.change_note).to_not be_nil
        expect(live_edition.reload.change_note).to_not be_nil
      end

      it "returns the change note" do
        expect(deleted_change_note).to eq(live_edition.change_note)
      end
    end
  end

  context "during a real run" do
    let(:dry_run) { false }

    context "the query doesn't match a change note" do
      let(:query) { "nonexistent" }

      it "raises an exception" do
        expect { call_change_note_remover }.to raise_error(DataHygiene::ChangeNoteNotFound)
      end
    end

    context "the query matches a change note" do
      let(:query) { "second" }

      let(:represent_downstream) { double }
      before do
        allow(represent_downstream).to receive(:call)
        allow(Commands::V2::RepresentDownstream)
          .to receive(:new).and_return(represent_downstream)
      end

      it "deletes the change note" do
        call_change_note_remover
        expect(superseded_edition.reload.change_note).to_not be_nil
        expect(live_edition.reload.change_note).to be_nil
      end

      it "removes change_history from the edition" do
        live_edition.update!(details: { change_history: [1, 2, 3], something_else: true })
        call_change_note_remover
        expect(live_edition.reload.details).to eq({ something_else: true })
      end

      it "represents to the content store" do
        expect(represent_downstream)
          .to receive(:call).with([live_edition.content_id])

        call_change_note_remover
      end

      it "returns the change note" do
        expect(deleted_change_note).to eq(live_edition.change_note)
      end
    end
  end
end
