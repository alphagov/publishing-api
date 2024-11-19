RSpec.describe GetEmbeddedContentService do
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
        expect { described_class.new(SecureRandom.uuid, nil, nil, nil).call }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
          expect(error.message).to eq("Could not find an edition to get embedded content for")
        end
      end
    end

    context "when the target_content_id matches a Document" do
      let(:target_content_id) { SecureRandom.uuid }
      let(:host_editions_stub) { double("ActiveRecord::Relation") }
      let(:count) { 12 }
      let(:total_pages) { 2 }
      let(:embedded_content_stub) { double(Queries::GetEmbeddedContent, call: host_editions_stub, count:, total_pages:) }
      let(:result_stub) { double }

      before do
        allow(Document).to receive(:find_by).and_return(anything)
        allow(Queries::GetEmbeddedContent).to receive(:new).and_return(embedded_content_stub)
        allow(Presenters::EmbeddedContentPresenter).to receive(:present).and_return(result_stub)
      end

      it "returns a presented form of the response from the query" do
        result = described_class.new(target_content_id, nil, nil, nil).call

        expect(result).to eq(result_stub)

        expect(Presenters::EmbeddedContentPresenter).to have_received(:present).with(
          target_content_id,
          host_editions_stub,
          count,
          total_pages,
        )
      end

      describe "pagination" do
        it "requests page zero by default" do
          described_class.new(target_content_id, nil, "", "").call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: nil, order_direction: nil, page: 0, per_page: nil
          )
        end

        it "requests a zero indexed page" do
          described_class.new(target_content_id, nil, "2", "").call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: nil, order_direction: nil, page: 1, per_page: nil
          )
        end

        it "accepts a per_page argument" do
          described_class.new(target_content_id, nil, "2", "5").call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: nil, order_direction: nil, page: 1, per_page: 5
          )
        end
      end

      describe "ordering" do
        it "does not send any ordering fields by default" do
          described_class.new(target_content_id, nil, nil, nil).call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: nil, order_direction: nil, page: 0, per_page: nil
          )
        end

        it "sends a field in ascending order when not preceded with a minus" do
          described_class.new(target_content_id, "something", nil, nil).call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: :something, order_direction: :asc, page: 0, per_page: nil
          )
        end

        it "sends a field in descending order when preceded with a minus" do
          described_class.new(target_content_id, "-something", nil, nil).call

          expect(Queries::GetEmbeddedContent).to have_received(:new).with(
            target_content_id, order_field: :something, order_direction: :desc, page: 0, per_page: nil
          )
        end

        describe "when the field is not valid" do
          before do
            allow(embedded_content_stub).to receive(:call).and_raise(KeyError)
          end

          it "returns a 422 error" do
            expect { described_class.new(target_content_id, "something", nil, nil).call }.to raise_error(CommandError) do |error|
              expect(error.code).to eq(422)
              expect(error.message).to eq("Invalid order field: something")
            end
          end
        end
      end
    end
  end
end
