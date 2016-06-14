require "rails_helper"

RSpec.describe ExperimentResultWorker do
  let(:name) { "some_experiment" }
  let(:id) { SecureRandom.uuid }

  let(:redis) { double(:redis) }
  let(:redis_key) { double(:redis_key) }

  let(:control_output) { "control output" }
  let(:control_duration) { 10.0 }

  let(:candidate_output) { "candidate output" }
  let(:candidate_duration) { 5.0 }

  let(:control) {
    double(:control,
      control?: true,
      candidate?: false,
      key: redis_key,
    )
  }
  let(:candidate) {
    double(:candidate,
      candidate?: true,
      control?: false,
      key: redis_key,
    )
  }

  subject { ExperimentResultWorker.new }

  before do
    allow(Sidekiq).to receive(:redis).and_yield(redis)
  end

  context "if we're the candidate" do
    let(:type) { :candidate }

    it "stores the run output and duration" do
      expect(ExperimentResult).to receive(:new)
        .with(name, id, type, redis, candidate_output, candidate_duration)
        .and_return(candidate)

      expect(candidate).to receive(:store_run_output)

      subject.perform(name, id, candidate_output, candidate_duration, type)
    end
  end

  context "if we're the control" do
    let(:type) { :control }

    before do
      expect(ExperimentResult).to receive(:new)
        .with(name, id, :control, redis, control_output, control_duration)
        .and_return(control)

      expect(ExperimentResult).to receive(:new)
        .with(name, id, :candidate, redis)
        .and_return(candidate)
    end

    context "and the candidate is available" do
      before do
        allow(candidate).to receive(:available?).and_return(true)
      end

      it "processes the run output with the candidate" do
        expect(control).to receive(:process_run_output).with(candidate)
        subject.perform(name, id, control_output, control_duration, type)
      end
    end

    context "but the candidate is unavailable" do
      before do
        allow(candidate).to receive(:available?).and_return(false)
        allow(described_class).to receive(:perform_in)
      end

      it "does not process the run output" do
        expect(control).not_to receive(:process_run_output)
        subject.perform(name, id, control_output, control_duration, type)
      end

      it "schedules the job to run again later" do
        args = [name, id, control_output, control_duration, type]
        expect(described_class).to receive(:perform_in).with(5.seconds, *args)
        subject.perform(*args)
      end
    end
  end
end
