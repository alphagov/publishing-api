RSpec.describe Graphql::ContentItemCompactor do
  describe "#compact" do
    it "should not remove fields with values" do
      compactor = described_class.new({})
      result = compactor.compact({ "present_key" => "some value"  })
      expect(result).to eq({ "present_key" => "some value" })
    end

    it "should remove optional fields with nil values (inline schema)" do
      compactor = described_class.new(
        "properties" => {
          "some_inline_nullable_property" => { "anyOf" => [ { "type" => "null" } ] }
        }
      )
      result = compactor.compact({ "some_inline_nullable_property" => nil })
      expect(result).to eq({})
    end

    it "should warn but leave required fields with nil values even if they are not allowed to be nil" do
      expect(Rails.logger).to receive(:warn)
      compactor = described_class.new(
        "required" => ["some_inline_non_nullable_property"],
        "properties" => {
          "some_inline_non_nullable_property" => { "type" => "string" }
        }
      )
      result = compactor.compact({ "some_inline_non_nullable_property" => nil })
      expect(result).to eq({ "some_inline_non_nullable_property" => nil })
    end

    it "should not remove required fields with nil values, and should not warn" do
      expect(Rails.logger).not_to receive(:warn)
      compactor = described_class.new(
        "required" => ["some_inline_nullable_property"],
        "properties" => {
          "some_inline_nullable_property" => { "anyOf" => [ { "type" => "null" } ] }
        }
      )
      result = compactor.compact({ "some_inline_nullable_property" => nil })
      expect(result).to eq({ "some_inline_nullable_property" => nil })
    end
  end
end
