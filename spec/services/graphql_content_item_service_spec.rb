RSpec.describe GraphqlContentItemService do
  it "returns the edition from the query result" do
    result = { "data" => { "edition" => "The best edition yet!" } }

    expect(GraphqlContentItemService.new(result).process).to eq("The best edition yet!")
  end

  context "when the edition has been unpublished" do
    it "returns unpublishing data from the error extensions" do
      result = {
        "errors" => [
          { "message" => "something unrelated" },
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
end
