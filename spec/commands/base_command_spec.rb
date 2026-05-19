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

  let(:validating_command) do
    Class.new(Commands::BaseCommand) do
      def self.name
        "Commands::ValidatingCommand"
      end

      def call
        payload[:record].save!
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

  it "raises CommandError with error_code from validation error" do
    allow(EventLogger).to receive(:log_command) do |_klass, _payload, &block|
      block.call(double(:event))
    end

    payload = {
      record: build(:unpublishing, type: "not_a_valid_type"),
    }

    expect {
      validating_command.call(payload)
    }.to raise_error(CommandError) do |error|
      expect(error.code).to eq(422)
      expect(error.error_code).to eq(:type_invalid)
      expect(error.message).to eq("Type is not included in the list")
      expect(error.error_details[:error][:fields]).to eq(
        { type: [{ code: :type_invalid, error: :inclusion, value: "not_a_valid_type" }] },
      )
    end
  end

  it "raises CommandError with :multiple_validation_errors code and error details" do
    allow(EventLogger).to receive(:log_command) do |_klass, _payload, &block|
      block.call(double(:event))
    end

    Class.new(Commands::BaseCommand) do
    end

    payload = {
      record: build(:unpublishing, type: nil),
    }

    expect {
      validating_command.call(payload)
    }.to raise_error(CommandError) do |error|
      expect(error.code).to eq(422)
      expect(error.error_code).to eq(:multiple_validation_errors)
      expect(error.message).to eq("Type can't be blank, Type is not included in the list")
      expect(error.error_details[:error][:fields]).to eq(
        {
          type: [
            { code: :type_missing, error: :blank },
            { code: :type_invalid, error: :inclusion, value: nil },
          ],
        },
      )
    end
  end
end
