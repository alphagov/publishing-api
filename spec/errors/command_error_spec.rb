RSpec.describe CommandError do
  describe ".with_error_handling" do
    it "raises a CommandError with content_store_validation_failed for 422 errors" do
      error = GdsApi::HTTPClientError.new(
        422,
        { "error" => { "message" => "Validation failed" } },
      )

      expect {
        described_class.with_error_handling do
          raise error
        end
      }.to raise_error(CommandError) { |command_error|
        expect(command_error.code).to eq(422)
        expect(command_error.error_code).to eq(:content_store_validation_failed)
        expect(command_error.error_details).to include(
          error: hash_including(
            code: 422,
            error_code: :content_store_validation_failed,
            message: error.message,
          ),
        )
      }
    end
  end

  describe "#initialize" do
    context "when not in production" do
      around do |example|
        ClimateControl.modify RAILS_ENV: "test" do
          example.run
        end
      end

      it "raises ArgumentError when error_code is missing for 422" do
        expect {
          described_class.new(
            code: 422,
            message: "Invalid",
          )
        }.to raise_error(ArgumentError, /Descriptive error code missing/)
      end

      it "raises ArgumentError for unknown error_code on 422" do
        expect {
          described_class.new(
            code: 422,
            error_code: :unknown_code,
            message: "Invalid",
          )
        }.to raise_error(ArgumentError, /Unknown error_code/)
      end
    end

    context "when in production environment" do
      before do
        allow(Rails).to receive(:env).and_return(
          ActiveSupport::StringInquirer.new("production"),
        )
      end

      it "notifies Sentry instead of raising when error_code is missing for 422" do
        expect(GovukError).to receive(:notify).with(
          "Descriptive error code missing for 422 error",
          level: "warning",
        )

        described_class.new(
          code: 422,
          message: "Invalid",
        )
      end

      it "notifies Sentry instead of raising for unknown error_code" do
        expect(GovukError).to receive(:notify).with(
          "Unknown error_code: unknown_code. Code must be included in ERROR_CODES",
          level: "warning",
        )

        described_class.new(
          code: 422,
          error_code: :unknown_code,
          message: "Invalid",
        )
      end
    end

    it "includes error_code in error_details when provided" do
      error = described_class.new(
        code: 422,
        message: "Validation failed",
        error_code: :validation_failed,
      )

      expect(error.error_details).to eq(
        {
          "error" => {
            "code" => 422,
            "error_code" => :validation_failed,
            "message" => "Validation failed",
          },
        },
      )
    end

    it "does not include error_code in error_details when not provided" do
      error = described_class.new(
        code: 500,
        message: "Internal server error",
      )

      expect(error.error_details).to eq(
        {
          "error" => {
            "code" => 500,
            "message" => "Internal server error",
          },
        },
      )
    end
  end
end
