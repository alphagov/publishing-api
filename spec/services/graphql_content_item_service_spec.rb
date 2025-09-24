RSpec.describe GraphqlContentItemService do
  let(:compactor) { instance_double(Graphql::ContentItemCompactor) }
  let(:graphql_content_item_service) { GraphqlContentItemService.new(compactor) }
  before do
    # For the purposes of these tests, the compact method can just pass through its input
    allow(compactor).to receive(:compact).and_invoke(-> { _1 })
  end

  it "returns the edition from the query result" do
    result = {
      "data" => {
        "edition" => {
          "title" => "The best edition yet!",
          "details" => {},
        },
      },
    }

    expect(graphql_content_item_service.process(result)).to eq({
      "details" => {},
      "title" => "The best edition yet!",
    })
  end

  it "deep sorts the hash, stringifying keys in the process" do
    result = {
      "data" => {
        "edition" => {
          "links" => {
            "organisations" => [
              { title: "The Big Dogs", base_path: "/government/big-dogs" },
            ],
          },
          "title" => "The best edition yet!",
          "details" => {
            "zeta" => {
              b: false,
              a: false,
            },
            "beta" => 123,
          },
        },
      },
    }

    expect(graphql_content_item_service.process(result)).to eq({
      "details" => {
        "beta" => 123,
        "zeta" => {
          "a" => false,
          "b" => false,
        },
      },
      "links" => {
        "organisations" => [
          { "base_path" => "/government/big-dogs", "title" => "The Big Dogs" },
        ],
      },
      "title" => "The best edition yet!",
    })
  end

  context "when the edition has been unpublished" do
    it "returns unpublishing data from the error extensions" do
      result = {
        "errors" => [
          {
            "message" => "Edition has been unpublished",
            "extensions" => { "a" => "hash" },
          },
        ],
        "data" => { "edition" => nil },
      }

      expect(graphql_content_item_service.process(result))
        .to eq({ "a" => "hash" })
    end
  end

  context "when there are genuine errors" do
    it "raises" do
      result = {
        "errors" => [
          { "message" => "Field 'bananas' doesn't exist on type 'Edition'" },
        ],
      }

      expect { graphql_content_item_service.process(result) }
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

      expect { graphql_content_item_service.process(result) }
        .to raise_error(GraphqlContentItemService::QueryResultError) do |error|
          expect(error.message).to eq(expected_error_message)
        end
    end
  end
end
