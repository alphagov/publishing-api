RSpec.describe Queries::GetEmbeddedContent do
  describe "#call" do
    it "returns data prepared by the presenter" do
      target_content_id = SecureRandom.uuid
      allow(Document).to receive(:find_by).with(content_id: target_content_id).and_return(anything)

      presenter_double = double(Presenters::Queries::EmbeddedContentPresenter)
      expect(Presenters::Queries::EmbeddedContentPresenter).to receive(:new)
        .with(target_content_id, kind_of(ActiveRecord::Relation))
        .and_return(presenter_double)

      stubbed_response = {}.to_json
      expect(presenter_double).to receive(:present).and_return(stubbed_response)

      result = described_class.new(target_content_id).call

      expect(result).to eq(stubbed_response)
    end

    context "when the target_content_id doesn't match a Document" do
      it "returns 404" do
        expect { described_class.new(SecureRandom.uuid).call }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
          expect(error.message).to eq("Could not find an edition to get embedded content for")
        end
      end
    end

    context "when the target_content_id does not match a live edition" do
      it "does not include it in the results" do
        organisation = create(:live_edition,
                              title: "bar",
                              document_type: "organisation",
                              schema_name: "organisation",
                              base_path: "/government/organisations/bar")
        content_block = create(:live_edition, document_type: "content_block_email_address",
                                              schema_name: "content_block_email_address",
                                              details: {
                                                "email_address" => "foo@example.com",
                                              })
        target_content_id = content_block.content_id
        _draft_edition = create(:edition, state: "draft",
                                          details: {
                                            body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
                                          },
                                          links_hash: {
                                            primary_publishing_organisation: [organisation.content_id],
                                            content_block_email_address: [content_block.content_id],
                                          })

        result = described_class.new(target_content_id).call

        expect(result).to eq({ content_id: target_content_id, total: 0, results: [] })
      end
    end

    context "when the target_content is not embedded in any live editions" do
      it "returns an empty results list" do
        target_content_id = SecureRandom.uuid
        allow(Document).to receive(:find_by).and_return(anything)

        result = described_class.new(target_content_id).call

        expect(result).to eq({ content_id: target_content_id, total: 0, results: [] })
      end
    end

    context "when there are live editions that embed the target content" do
      it "only passes them to the presenter" do
        organisation = create(:live_edition,
                              title: "bar",
                              document_type: "organisation",
                              schema_name: "organisation",
                              base_path: "/government/organisations/bar")
        content_block = create(:live_edition, document_type: "content_block_email_address",
                                              schema_name: "content_block_email_address",
                                              details: {
                                                "email_address" => "foo@example.com",
                                              })
        target_content_id = content_block.content_id
        host_editions = create_list(:live_edition, 2,
                                    details: {
                                      body: "<p>{{embed:email_address:#{target_content_id}}}</p>\n",
                                    },
                                    links_hash: {
                                      primary_publishing_organisation: [organisation.content_id],
                                      content_block_email_address: [target_content_id],
                                    })
        _unwanted_edition = create(:live_edition)

        # The edition records we create in test can't be used as they are as assertions.
        # We load new fields into the Edition using the SQL Select.
        edition_doubles = host_editions.map do |host_edition|
          double("Edition",
                 id: host_edition.id,
                 title: host_edition.title,
                 base_path: host_edition.base_path,
                 document_type: host_edition.document_type,
                 primary_publishing_organisation_content_id: organisation.content_id,
                 primary_publishing_organisation_title: organisation.title,
                 primary_publishing_organisation_base_path: organisation.base_path)
        end

        expected_editions = edition_doubles.map do |edition_double|
          have_attributes(
            id: edition_double.id,
            title: edition_double.title,
            base_path: edition_double.base_path,
            document_type: edition_double.document_type,
            primary_publishing_organisation_content_id: edition_double.primary_publishing_organisation_content_id,
            primary_publishing_organisation_title: edition_double.primary_publishing_organisation_title,
            primary_publishing_organisation_base_path: edition_double.primary_publishing_organisation_base_path,
          )
        end

        presenter_double = double(Presenters::Queries::EmbeddedContentPresenter)
        expect(Presenters::Queries::EmbeddedContentPresenter).to receive(:new) do |_, editions|
          editions.each_with_index do |edition, index|
            expect(edition).to expected_editions[index]
          end
          presenter_double
        end

        allow(presenter_double).to receive(:present).and_return({}.to_json)

        described_class.new(target_content_id).call
      end
    end
  end
end
