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
      "withdrawn_notice" => {},
    })
  end

  context "withdrawn_notice" do
    it "sets the withdrawn notice to an empty hash when not in the result" do
      result = {
        "data" => {
          "edition" => {
            "title" => "The best edition yet!",
            "details" => {},
          },
        },
      }

      expect(GraphqlContentItemService
        .new(result)
        .process["withdrawn_notice"]).to eq({})
    end

    it "sets the withdrawn notice to an empty hash when nil" do
      result = {
        "data" => {
          "edition" => {
            "title" => "The best edition yet!",
            "details" => {},
            "withdrawn_notice" => nil,
          },
        },
      }

      expect(GraphqlContentItemService.new(result).process["withdrawn_notice"])
        .to eq({})
    end

    it "doesn't touch a non-nil withdrawn notice" do
      withdrawn_notice = {
        explanation: "my explanation",
        withdrawn_at: "2016-04-11T10:52:00.000+01:00",
      }
      result = {
        "data" => {
          "edition" => {
            "title" => "The best edition yet!",
            "details" => {},
            "withdrawn_notice" => withdrawn_notice,
          },
        },
      }

      expect(GraphqlContentItemService.new(result).process["withdrawn_notice"])
        .to eq(withdrawn_notice)
    end
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
