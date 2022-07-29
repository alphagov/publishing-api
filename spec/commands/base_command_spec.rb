RSpec.describe Commands::BaseCommand do
  let(:top_level_worker) { double(:top_level_worker, some_method: nil) }
  let(:nested_worker) { double(:nested_worker, some_method: nil) }

  let(:top_level_command) do
    Class.new(Commands::BaseCommand) do
      def self.name
        "Commands::TopLevelCommand"
      end

      def call
        after_transaction_commit do
          payload[:top_level_worker].some_method
        end

        Commands::NestedCommand.call(payload, callbacks:, nested: true)
      end
    end
  end

  let(:nested_command) do
    Class.new(Commands::BaseCommand) do
      def self.name
        "Commands::NestedCommand"
      end

      def call
        after_transaction_commit do
          payload[:nested_worker].some_method
        end
      end
    end
  end

  let(:slow_command) do
    Class.new(Commands::BaseCommand) do
      def self.name
        "Commands::SlowCommand"
      end

      def call
        sleep 1
        :foo
      end
    end
  end

  before { stub_const("Commands::NestedCommand", nested_command) }

  describe "callbacks for nested commands" do
    it "executes callbacks at the top level of the command tree" do
      expect(top_level_command).to receive(:execute_callbacks)
      expect(nested_command).not_to receive(:execute_callbacks)

      top_level_command.call({})
    end

    it "executes all callbacks from every level of the command tree" do
      expect(top_level_worker).to receive(:some_method)
      expect(nested_worker).to receive(:some_method)

      payload = {
        top_level_worker:,
        nested_worker:,
      }

      top_level_command.call(payload)
    end
  end

  describe "timing" do
    it "sends a command's duration to statsd" do
      expect(PublishingAPI.service(:statsd)).to receive(:timing) do |name, time, sample_rate|
        expect(name).to eq "Commands.SlowCommand"
        expect(time).to within(100).of(1000)
        expect(sample_rate).to eq 1
      end

      expect(slow_command.call({ foo: "bar" })).to eq :foo
    end
  end
end
