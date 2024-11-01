RSpec.describe GetHostContentService do
  describe "#call" do
    let(:organisation) do
      edition_params = {
        title: "bar",
        document: create(:document),
        document_type: "organisation",
        schema_name: "organisation",
        base_path: "/government/organisations/bar",
      }

      create(:superseded_edition, **edition_params)
      live_edition = create(:live_edition, **edition_params.merge({ user_facing_version: 2 }))
      create(:draft_edition, **edition_params.merge({ user_facing_version: 3 }))

      live_edition
    end

    let(:content_block) do
      create(:live_edition,
             document_type: "content_block_email_address",
             schema_name: "content_block_email_address",
             details: {
               "email_address" => "foo@example.com",
             })
    end

    context "when the target_content_id doesn't match a Document" do
      it "returns 404" do
        expect { described_class.new(SecureRandom.uuid).call }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
          expect(error.message).to eq("Could not find an edition to get embedded content for")
        end
      end
    end

    context "when the target_content_id matches a Document" do
      it "returns a presented form of the response from the query" do
        target_content_id = SecureRandom.uuid
        allow(Document).to receive(:find_by).and_return(anything)

        host_editions_stub = double("ActiveRecord::Relation")
        embedded_content_stub = double(Queries::GetEmbeddedContent, call: host_editions_stub)
        result_stub = double

        allow(Queries::GetEmbeddedContent).to receive(:new).and_return(embedded_content_stub)

        allow(Presenters::EmbeddedContentPresenter).to receive(:present).and_return(result_stub)

        result = described_class.new(target_content_id).call

        expect(result).to eq(result_stub)

        expect(Presenters::EmbeddedContentPresenter).to have_received(:present).with(
          target_content_id,
          host_editions_stub,
        )
      end
    end
  end
end
