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
        result = compactor.compact({ "some_field" => "some value", "links" => {} })
        expect(result).to eq({ "some_field" => "some value", "links" => {} })
      end

      it "should remove optional fields with nil values" do
        result = compactor.compact({ "some_optional_field" => nil, "links" => {} })
        expect(result).to eq({ "links" => {} })
      end

      it "should not remove required fields with nil values" do
        result = compactor.compact({ "some_required_field" => nil, "links" => {} })
        expect(result).to eq({ "some_required_field" => nil, "links" => {} })
      end
    end

    context "details fields" do
      it "should not remove fields with values" do
        result = compactor.compact({ "details" => { "some_field" => "some value" }, "links" => {} })
        expect(result).to eq({ "details" => { "some_field" => "some value" }, "links" => {} })
      end

      it "should remove optional fields with nil values" do
        result = compactor.compact({ "details" => { "some_optional_field" => nil }, "links" => {} })
        expect(result).to eq({ "details" => {}, "links" => {} })
      end

      it "should not remove required fields with nil values" do
        result = compactor.compact("details" => { "some_required_details_field" => nil }, "links" => {})
        expect(result).to eq("details" => { "some_required_details_field" => nil }, "links" => {})
      end
    end

    context "links" do
      it "should add an empty links hash for a content-item with no links" do
        result = compactor.compact({})
        expect(result).to eq("links" => {})
      end

      it "should add empty links hashes for nested content-items with no links" do
        result = compactor.compact("links" => {
          "some_link_type" => [{}, {}],
          "some_other_link_type" => [{}, {}],
        })
        expect(result).to eq("links" => {
          "some_link_type" => [{ "links" => {} }, { "links" => {} }],
          "some_other_link_type" => [{ "links" => {} }, { "links" => {} }],
        })
      end

      it "should not remove link arrays with items" do
        result = compactor.compact(
          "links" => {
            "some_link_type" => [{ "some_content_item" => "which exists", "links" => {} }],
          },
        )
        expect(result).to eq(
          "links" => {
            "some_link_type" => [{ "some_content_item" => "which exists", "links" => {} }],
          },
        )
      end

      it "should remove empty link arrays" do
        result = compactor.compact(
          "links" => {
            "some_link_type" => [],
            "some_other_link_type" => [],
          },
        )
        expect(result).to eq("links" => {})
      end

      it "should remove nested empty link arrays" do
        result = compactor.compact(
          "links" => {
            "some_link_type" => [
              {
                "some_content_item" => "which exists",
                "links" => {
                  "some_link_type" => [],
                },
              },
            ],
            "some_other_link_type" => [
              {
                "some_content_item" => "which exists",
                "links" => {
                  "some_link_type" => [
                    {
                      "some_content_item" => "which exists",
                      "links" => {
                        "some_link_type" => [],
                      },
                    },
                  ],
                },
              },
            ],
          },
        )
        expect(result).to eq(
          "links" => {
            "some_link_type" => [
              {
                "links" => {},
                "some_content_item" => "which exists",
              },
            ],
            "some_other_link_type" => [
              {
                "links" => {
                  "some_link_type" => [
                    {
                      "links" => {},
                      "some_content_item" => "which exists",
                    },
                  ],
                },
                "some_content_item" => "which exists",
              },
            ],
          },
        )
      end
    end
  end
end
