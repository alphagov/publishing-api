RSpec.describe Queries::GetEmbeddedEditionsFromHostEdition do
  describe ".call" do
    let(:embedded_content_id) { SecureRandom.uuid }
    let(:host_edition) do
      create(:live_edition,
             details: {
               body: "<p>{{embed:email_address:#{embedded_content_id}}}</p>\n",
             },
             links_hash: {
               embed: [embedded_content_id],
             })
    end

    let(:block_document) do
      create(:document, content_id: embedded_content_id)
    end

    let!(:content_block) do
      create(:live_edition,
             document: block_document,
             document_type: "content_block_email_address",
             schema_name: "content_block_email_address",
             details: {
               "email_address" => "foo@example.com",
             })
    end

    let!(:draft_content_block) do
      create(:draft_edition,
             document: block_document,
             user_facing_version: 2,
             document_type: "content_block_email_address",
             schema_name: "content_block_email_address",
             details: {
               "email_address" => "another@example.com",
             })
    end

    context "when there are live and draft embedded editions" do
      it "returns embedded editions" do
        expect(described_class.call(edition: host_edition)).to eq({ embedded_content_id => content_block })
      end
    end
  end
end
