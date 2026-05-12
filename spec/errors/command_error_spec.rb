RSpec.describe CommandError do
  describe ".with_error_handling" do
    it "raises a CommandError with content_store_validation_failed for 422 errors" do
      error = GdsApi::HTTPUnprocessableEntity.new(
        422,
        { "error" => { "message" => "Validation failed" } },
      )

      expect {
        described_class.with_error_handling do
          raise error
        end
      }.to raise_error(CommandError) { |command_error|
        expect(command_error.code).to eq(422)

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
