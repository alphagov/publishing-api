RSpec.describe GraphqlContentItemService do
  it "returns the edition from the query result" do
    result = {
      "data" => {
        "edition" => {
          "title" => "The best edition yet!",
          "details" => { "something" => "great" },
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({
      "details" => { "something" => "great" },
      "title" => "The best edition yet!",
    })
  end

  it "removes empty top-level fields (excluding false)" do
    result = {
      "data" => {
        "edition" => {
          "non_empty_array" => [1, 2, 3],
          "empty_array" => [],
          "true" => true,
          "false" => false,
          "non_empty_hash" => { "a" => 1 },
          "empty_hash" => {},
          "null" => nil,
          "number" => 1,
          "non_empty_string" => "howdy",
          "empty_string" => "",
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({
      "non_empty_array" => [1, 2, 3],
      "true" => true,
      "false" => false,
      "non_empty_hash" => { "a" => 1 },
      "number" => 1,
      "non_empty_string" => "howdy",
    })
  end

  it "removes empty nested fields (excluding false)" do
    result = {
      "data" => {
        "edition" => {
          "details" => {
            "non_empty_array" => [1, 2, 3],
            "empty_array" => [],
            "true" => true,
            "false" => false,
            "non_empty_hash" => { "a" => 1 },
            "empty_hash" => {},
            "null" => nil,
            "number" => 1,
            "non_empty_string" => "howdy",
            "empty_string" => "",
          },
        },
      },
    }

    expect(GraphqlContentItemService.new(result).process).to eq({ "details" => {
      "non_empty_array" => [1, 2, 3],
      "true" => true,
      "false" => false,
      "non_empty_hash" => { "a" => 1 },
      "number" => 1,
      "non_empty_string" => "howdy",
    } })
  end

  it "removes fields if all descendent leaf nodes are empty" do
    result = {
      "data" => {
        "edition" => {
          "not_yet_empty_hash" => {
            "empty" => nil
          },
          "not_yet_empty_array" => [
            { "empty" => nil }
          ]
        }
      }
    }

    expect(GraphqlContentItemService.new(result).process).to eq({})
  end

  it "transforms symbol keys to strings" do
    result = {
      "data" => {
        "edition" => {
          "details" => {
            "my_detail" => {
              symbolic: true
            }
          }
        }
      }
    }

    expect(GraphqlContentItemService.new(result).process).to eq(
      { "details" => { "my_detail" => { "symbolic" => true } } }
    )
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
