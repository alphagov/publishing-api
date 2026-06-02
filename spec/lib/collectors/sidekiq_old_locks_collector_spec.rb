RSpec.describe(Collectors::SidekiqOldLocksCollector) do
  describe "#metrics" do
    let(:gauge) { instance_double(PrometheusExporter::Metric::Gauge) }

    before do
      allow(PrometheusExporter::Metric::Gauge)
        .to receive(:new)
        .and_return(gauge)

      allow(gauge).to receive(:observe)
    end

    context "when there are no locks older than one hour" do
      before do
        allow_any_instance_of(SidekiqOldLocks::Web::Helpers).to receive(:old_digests).and_return([])
      end
      it "set a zero value" do
        described_class.new.metrics

        expect(gauge).to have_received(:observe).with(0)
      end
    end

    context "when there are locks older than one hour" do
      before do
        allow_any_instance_of(SidekiqOldLocks::Web::Helpers).to receive(:old_digests).and_return(
          [
            { digest: "uniquejobs:f2f8d140b3191770c992ad238c95dbb9", created_at: 1_778_154_689.8511593, state: :active },
          ],
        )
      end
      it "sets the value" do
        described_class.new.metrics

        expect(gauge).to have_received(:observe).with(1)
      end
    end
  end
end
