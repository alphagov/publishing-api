RSpec.describe GraphqlContentItemService do
  it "returns the edition from the query result" do
    result = {
      "data" => {
        "edition" => {
          "title" => "The best edition yet!",
          "details" => {},
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({
      "details" => {},
      "title" => "The best edition yet!",
    })
  end

  it "removes null top-level fields" do
    result = {
      "data" => {
        "edition" => {
          "array" => [1, 2, 3],
          "boolean" => true,
          "details" => {},
          "hash" => { "a" => 1 },
          "null" => nil,
          "number" => 1,
          "string" => "howdy",
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({
      "array" => [1, 2, 3],
      "boolean" => true,
      "details" => {},
      "hash" => { "a" => 1 },
      "number" => 1,
      "string" => "howdy",
    })
  end

  it "removes null fields from the details hash" do
    result = {
      "data" => {
        "edition" => {
          "details" => {
            "array" => [1, 2, 3],
            "boolean" => true,
            "hash" => { "a" => 1 },
            "null" => nil,
            "number" => 1,
            "string" => "howdy",
          },
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({ "details" => {
      "array" => [1, 2, 3],
      "boolean" => true,
      "hash" => { "a" => 1 },
      "number" => 1,
      "string" => "howdy",
    } })
  end

  context "when the edition has been unpublished" do
    it "returns unpublishing data from the error extensions" do
      result = {
        "errors" => [
          {
            "message" => "Edition has been unpublished",
            "extensions" => "presented unpublishing data",
          },
        ],
        "data" => { "edition" => nil },
      }

      expect(GraphqlContentItemService.new(result).process)
        .to eq("presented unpublishing data")
    end
  end

  context "when there are genuine errors" do
    it "raises" do
      result = {
        "errors" => [
          { "message" => "Field 'bananas' doesn't exist on type 'Edition'" },
        ],
      }

      expect { GraphqlContentItemService.new(result).process }
        .to raise_error(GraphqlContentItemService::QueryResultError) do |error|
          expect(error.message).to eq(
            "Field 'bananas' doesn't exist on type 'Edition'",
          )
        end
    end

    it "raises with all error messages when there are multiple" do
      result = {
        "errors" => [
          { "message" => "Field 'bananas' doesn't exist on type 'Edition'" },
          { "message" => "Field 'kiwi' doesn't exist on type 'Details'" },
        ],
      }
      expected_error_message = "Field 'bananas' doesn't exist on type 'Edition'\nField 'kiwi' doesn't exist on type 'Details'"

      expect { GraphqlContentItemService.new(result).process }
        .to raise_error(GraphqlContentItemService::QueryResultError) do |error|
          expect(error.message).to eq(expected_error_message)
        end
    end
  end
end
