RSpec.describe GraphqlContentItemService do
  let(:compactor) { instance_double(Graphql::ContentItemCompactor) }
  let(:graphql_content_item_service) { GraphqlContentItemService.new(compactor) }
  before { allow(compactor).to receive(:compact).and_invoke(->(graphql_response) { graphql_response }) }

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

  it "doesn't remove required fields when value is nil" do
    result = {
      "data" => {
        "edition" => {
          "title" => "The best edition yet!",
          "details" => {},
          "description" => nil,
        },
      },
    }

    expect(graphql_content_item_service.process(result)).to eq({
      "details" => {},
      "title" => "The best edition yet!",
      "description" => nil,
    })
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

      expect(graphql_content_item_service.process(result))
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
