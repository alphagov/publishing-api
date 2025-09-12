RSpec.describe Graphql::ContentItemCompactor do
  describe "#compact" do
    context "top level fields" do
      it "should not remove fields with values" do
        compactor = described_class.new({})
        result = compactor.compact({ "present_key" => "some value" })
        expect(result).to eq({ "present_key" => "some value" })
      end

      it "should remove optional fields with nil values" do
        compactor = described_class.new(
          "properties" => {
            "some_nullable_property" => { "anyOf" => [{ "type" => "null" }] },
          },
        )
        result = compactor.compact({ "some_nullable_property" => nil })
        expect(result).to eq({})
      end

      it "should warn but leave required fields with nil values even if they are not allowed to be nil" do
        expect(Rails.logger).to receive(:warn)
        compactor = described_class.new(
          "required" => %w[some_non_nullable_property],
          "properties" => {
            "some_non_nullable_property" => { "type" => "string" },
          },
        )
        result = compactor.compact({ "some_non_nullable_property" => nil })
        expect(result).to eq({ "some_non_nullable_property" => nil })
      end

      it "should not remove required fields with nil values, and should not warn" do
        expect(Rails.logger).not_to receive(:warn)
        compactor = described_class.new(
          "required" => %w[some_nullable_property],
          "properties" => {
            "some_nullable_property" => { "anyOf" => [{ "type" => "null" }] },
          },
        )
        result = compactor.compact({ "some_nullable_property" => nil })
        expect(result).to eq({ "some_nullable_property" => nil })
      end
    end

    context "details fields" do
      it "should not remove fields with values" do
        compactor = described_class.new({})
        result = compactor.compact({ "details" => { "body" => "some value" } })
        expect(result).to eq({ "details" => { "body" => "some value" } })
      end

      it "should remove optional fields with nil values" do
        compactor = described_class.new(
          "properties" => {
            "details" => {
              "properties" => {
                "some_nullable_property" => { "anyOf" => [{ "type" => "null" }] },
              },
            },
          },
        )
        result = compactor.compact({ "details" => { "some_nullable_property" => nil } })
        expect(result).to eq({ "details" => {} })
      end

      it "should warn but leave required fields with nil values even if they are not allowed to be nil" do
        expect(Rails.logger).to receive(:warn)
        compactor = described_class.new(
          "definitions" => {
            "details" => {
              "required" => %w[some_non_nullable_property],
            },
          },
          "properties" => {
            "details" => {
              "properties" => {
                "some_non_nullable_property" => { "type" => "string" },
              },
            },
          },
        )
        result = compactor.compact("details" => { "some_non_nullable_property" => nil })
        expect(result).to eq("details" => { "some_non_nullable_property" => nil })
      end

      it "should not remove required fields with nil values, and should not warn" do
        expect(Rails.logger).not_to receive(:warn)
        compactor = described_class.new(
          "definitions" => {
            "details" => {
              "required" => %w[some_nullable_property],
            },
          },
          "properties" => {
            "details" => {
              "properties" => {
                "some_nullable_property" => { "anyOf" => [{ "type" => "null" }] },
              },
            },
          },
        )
        result = compactor.compact("details" => { "some_nullable_property" => nil })
        expect(result).to eq("details" => { "some_nullable_property" => nil })
      end
    end

    context "empty links" do
      let(:compactor) { described_class.new({}) }

      it "should remove any links keys that have empty array values" do
        result = compactor.compact("links" => { "empty_link_type" => [], "present_link_type" => [{}] })
        expect(result).to eq("links" => { "present_link_type" => [{}] })
      end

      it "should remove any nested links keys that have empty array values" do
        result = compactor.compact(
          "links" => {
            "empty_link_type" => [],
            "nested_1" => [
              {
                "links" => {
                  "empty_link_type" => [],
                  "nested_2" => [
                    {
                      "links" => { "empty_link_type" => [] },
                    },
                  ],
                },
              },
            ],
          },
        )
        expect(result).to eq("links" => { "nested_1" => [{ "links" => { "nested_2" => [{ "links" => {} }] } }] })
      end
    end
  end
end
