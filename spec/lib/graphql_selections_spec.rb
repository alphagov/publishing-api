RSpec.describe GraphqlSelections do
  describe ".with_edition_fields" do
    it "nests the editions selections under `editions`" do
      selections = GraphqlSelections.with_edition_fields(
        %i[id base_path],
      )

      expect(selections).to eq({ editions: %i[id base_path] })
    end

    it "resolves field names that aren't database columns" do
      selections = GraphqlSelections.with_edition_fields(
        %i[content_id links web_url],
      )

      expect(selections).to eq({
        editions: %i[id content_store base_path],
        documents: %i[content_id],
      })
    end

    it "does not support withrawn_notice" do
      selections = GraphqlSelections.with_edition_fields(
        %i[id withdrawn_notice],
      )

      expect(selections).to eq({ editions: %i[id] })
    end
  end

  describe ".with_root_edition_fields" do
    it "acts like with_edition_fields but with support for withdrawn_notice" do
      selections = GraphqlSelections.with_root_edition_fields(
        %i[id content_id withdrawn_notice],
      )

      expect(selections).to eq({
        editions: %i[id],
        documents: %i[content_id],
        unpublishings: [
          "created_at AS unpublishing_created_at",
          "explanation AS unpublishing_explanation",
          "type AS unpublishing_type",
          "unpublished_at AS unpublishing_unpublished_at",
        ],
      })
    end
  end

  describe "#selects_from_table?" do
    it "confirms whether we've selected columns from the given table" do
      selections = GraphqlSelections.new(editions: %i[id])

      expect(selections.selects_from_table?(:editions)).to be true
      expect(selections.selects_from_table?(:documents)).to be false
    end
  end

  describe "ALL_EDITION_COLUMNS" do
    it "is an up-to-date list of the Edition model's database columns" do
      expect(GraphqlSelections::ALL_EDITION_COLUMNS).to match_array(
        Edition.attribute_names.map(&:to_sym),
      )
    end
  end
end
