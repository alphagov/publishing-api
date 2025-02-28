RSpec.describe GraphqlSelections do
  describe ".with_edition_fields" do
    it "nests the editions selections under `editions`" do
      selections = GraphqlSelections.with_edition_fields(
        %i[id base_path],
      )

      expect(selections.to_select_args).to eq({editions: %i[id base_path]})
    end

    it "resolves field names that aren't database columns" do
      selections = GraphqlSelections.with_edition_fields(
        %i[content_id links web_url],
      )

      expect(selections.to_select_args).to eq({
        editions: %i[id content_store base_path],
        documents: %i[content_id],
      })
    end
  end

  describe "#insert" do
    it "merges the column names with existing ones for the same table" do
      selections = GraphqlSelections.new(editions: %i[id])

      selections.insert(:editions, %i[content_store])

      expect(selections.to_select_args).to eq({editions: %i[id content_store]})
    end

    it "creates entries for new tables" do
      selections = GraphqlSelections.new(editions: %i[id])

      selections.insert(:documents, %i[content_id])

      expect(selections.to_select_args).to eq({
        editions: %i[id],
        documents: %i[content_id],
      })
    end
  end

  describe "#merge" do
    it "deeply merges the given GraphqlSelections into itself" do
      selections = GraphqlSelections.new(
        editions: %i[id content_store],
        documents: %i[content_id],
      )
      other_selections = GraphqlSelections.new(
        editions: %i[id base_path],
        documents: %i[locale],
      )

      selections.merge(other_selections)

      expect(selections.to_select_args).to eq({
        editions: %i[id content_store base_path],
        documents: %i[content_id locale],
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
