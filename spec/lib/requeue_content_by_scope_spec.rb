RSpec.describe RequeueContentByScope do
  subject(:requeue_content_by_scope) { described_class.new(Edition.all, action:) }

  let(:action) { "reticulate.splines" }

  let(:queue) { instance_double(Sidekiq::Queue, size: 0) }

  context "when a blank action is provided" do
    let(:action) { "" }

    it "raises an error on initialize" do
      expect { requeue_content_by_scope }.to raise_error(ArgumentError)
    end
  end

  context "when a major action is provided" do
    let(:action) { "major.disaster" }

    it "raises an error on initialize" do
      expect { requeue_content_by_scope }.to raise_error(ArgumentError)
    end
  end

  describe "#call" do
    let!(:editions) { create_list(:edition, 3) }
    let!(:version) { create(:event, id: 1989) }

    before do
      allow(Sidekiq::Queue).to receive(:new).and_return(queue)
      allow(RequeueContentJob).to receive(:perform_async)
    end

    it "requeues content for the provided scope" do
      requeue_content_by_scope.call

      editions.each do |edition|
        expect(RequeueContentJob).to have_received(:perform_async)
          .with(edition.id, 1989, "reticulate.splines").once
      end
      expect(RequeueContentJob).to have_received(:perform_async).exactly(3).times
    end

    context "when the queue has reached its limit" do
      let(:queue_size) { 5_001 }

      before do
        allow(queue).to receive(:size).and_return(5001, 4999)
        allow(requeue_content_by_scope).to receive(:sleep)
      end

      it "waits for the queue size to decrease" do
        requeue_content_by_scope.call

        expect(requeue_content_by_scope).to have_received(:sleep).at_least(:once)
      end

      it "logs a warning message" do
        expect { requeue_content_by_scope.call }.to output(
          /Pending jobs have exceeded limit/,
        ).to_stderr
      end
    end
  end
end
