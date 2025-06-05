RSpec.describe "Rake tasks for maintaining data hygiene" do
  describe "data_hygiene:discard_drafts_and_unpublish" do
    before do
      Rake::Task["data_hygiene:discard_drafts_and_unpublish"].reenable
    end

    context "when the document is present" do
      let(:document) { create(:document) }
      let(:expected_payload) { { content_id: document.content_id, locale: document.locale, type: "gone" } }

      it "runs the process to unpublish the document with the locale" do
        expect(Commands::V2::Unpublish).to receive(:call).with(expected_payload).once

        Rake::Task["data_hygiene:discard_drafts_and_unpublish"].invoke(document.content_id)
      end

      context "and when a draft is present" do
        before do
          create(:edition, document:).publish
          create(:edition, document:, user_facing_version: 2)
        end

        it "runs the process to discard a draft with the locale" do
          expect(Commands::V2::DiscardDraft).to receive(:call).with({ content_id: document.content_id, locale: "en" }).once
          expect(Commands::V2::Unpublish).to receive(:call).with(expected_payload).once

          Rake::Task["data_hygiene:discard_drafts_and_unpublish"].invoke(document.content_id)
        end
      end

      context "and when there are multiple locales for the document" do
        let(:document_es) { create(:document, content_id: document.content_id, locale: "es") }
        let(:expected_payload_es) { { content_id: document_es.content_id, locale: document_es.locale, type: "gone" } }

        it "runs the process to unpublish documents in all locales" do
          expect(Commands::V2::Unpublish).to receive(:call).with(expected_payload).once
          expect(Commands::V2::Unpublish).to receive(:call).with(expected_payload_es).once

          Rake::Task["data_hygiene:discard_drafts_and_unpublish"].invoke(document.content_id)
        end
      end
    end

    it "raises an error if a content id is not provided" do
      expect { Rake::Task["data_hygiene:discard_drafts_and_unpublish"].execute }
        .to raise_error("Missing parameter: content_id").and output("Missing parameter: content_id\n").to_stderr
    end

    it "raises an error if a the document is not present" do
      expect { Rake::Task["data_hygiene:discard_drafts_and_unpublish"].invoke("content_id") }
        .to raise_error("Content ID content_id not found").and output("Content ID content_id not found\n").to_stderr
    end
  end
end
