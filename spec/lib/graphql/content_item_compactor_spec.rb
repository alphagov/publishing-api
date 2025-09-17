RSpec.describe Graphql::ContentItemCompactor do
  describe "#compact" do
    let(:schema) do
      {
        "required" => %w[some_required_field],
        "definitions" => {
          "details" => {
            "required" => %w[some_required_details_field],
          },
        },
      }
    end
    let(:compactor) { described_class.new(schema) }

    context "top level fields" do
      it "should not remove fields with values" do
        expect(compactor.compact({ "some_field" => "some value" })).to eq({ "some_field" => "some value" })
      end

      it "should remove optional fields with nil values" do
        expect(compactor.compact({ "some_optional_field" => nil })).to eq({})
      end

      it "should not remove required fields with nil values" do
        expect(compactor.compact({ "some_required_field" => nil })).to eq({ "some_required_field" => nil })
      end
    end

    context "details fields" do
      it "should not remove fields with values" do
        result = compactor.compact({ "details" => { "some_field" => "some value" } })
        expect(result).to eq({ "details" => { "some_field" => "some value" } })
      end

      it "should remove optional fields with nil values" do
        result = compactor.compact({ "details" => { "some_optional_field" => nil } })
        expect(result).to eq({ "details" => {} })
      end

      it "should not remove required fields with nil values" do
        result = compactor.compact("details" => { "some_required_details_field" => nil })
        expect(result).to eq("details" => { "some_required_details_field" => nil })
      end
    end
  end
end
