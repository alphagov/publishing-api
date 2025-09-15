RSpec.describe Graphql::ContentItemCompactor do
  describe "#compact" do
    it "removes null top-level fields" do
      result = {
        "array" => [1, 2, 3],
        "boolean" => true,
        "details" => {},
        "hash" => { "a": 1 },
        "null" => nil,
        "number" => 1,
        "string" => "howdy",
      }

      described_class.new.compact!(result)

      expect(result).to eq({
        "array" => [1, 2, 3],
        "boolean" => true,
        "details" => {},
        "hash" => { "a": 1 },
        "number" => 1,
        "string" => "howdy",
      })
    end

    it "removes null fields from the details hash" do
      result = {
        "details" => {
          "array" => [1, 2, 3],
          "boolean" => true,
          "hash" => { "a": 1 },
          "null" => nil,
          "number" => 1,
          "string" => "howdy",
        },
      }

      described_class.new.compact!(result)
      expect(result).to eq({ "details" => {
        "array" => [1, 2, 3],
        "boolean" => true,
        "hash" => { "a": 1 },
        "number" => 1,
        "string" => "howdy",
      } })
    end
  end
end
