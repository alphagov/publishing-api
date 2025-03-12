RSpec.describe GetHostContentItemService do
  describe "#call" do
    let(:target_content_id) { SecureRandom.uuid }
    let(:host_content_id) { SecureRandom.uuid }

    context "when the target_content_id doesn't match a Document" do
      it "returns 404" do
        expect { described_class.new(target_content_id, host_content_id).call }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
          expect(error.message).to eq("Could not find an edition to get host content for")
        end
      end
    end

    context "when the host_content_id doesn't match a Document" do
      before do
        allow(Document).to receive(:find_by).with(content_id: target_content_id).and_return(anything)
      end

      it "returns 404" do
        expect { described_class.new(target_content_id, host_content_id).call }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
          expect(error.message).to eq("Could not find host_content_id #{host_content_id} in host content for #{target_content_id}")
        end
      end
    end

    context "when content for host_content_id exists" do
      let(:result_stub) { double("Queries::GetHostContent::Result") }
      let(:host_editions_stub) { [result_stub] }
      let(:embedded_content_stub) { double(Queries::GetHostContent, call: [result_stub]) }
      let(:result_stub) { double }

      before do
        allow(Document).to receive(:find_by).and_return(anything)
        allow(Queries::GetHostContent).to receive(:new).and_return(embedded_content_stub)
        allow(Presenters::HostContentItemPresenter).to receive(:present).and_return(result_stub)
      end

      it "returns a presented form of the response from the query" do
        result = described_class.new(target_content_id, host_content_id).call

        expect(result).to eq(result_stub)

        expect(Presenters::HostContentItemPresenter).to have_received(:present).with(result_stub)
      end

      context "when a locale is specified" do
        let(:locale) { "cy" }

        before do
          allow(Queries::GetHostContent).to receive(:new).with(target_content_id, host_content_id:, locale:).and_return(embedded_content_stub)
        end

        it "returns a presented form of the response from the query" do
          result = described_class.new(target_content_id, host_content_id, locale).call

          expect(result).to eq(result_stub)

          expect(Presenters::HostContentItemPresenter).to have_received(:present).with(result_stub)
        end
      end
    end
  end
end
