RSpec.describe GraphqlSelections do
  describe ".with_edition_fields" do
    it "always includes selections necessary for fetching change notes from the database" do
      selections = GraphqlSelections.with_edition_fields([])

      expect(selections.to_h).to eq({ editions: %i[document_id user_facing_version] })
    end

    it "nests the editions selections under `editions`" do
      selections = GraphqlSelections.with_edition_fields(
        %i[id base_path],
      )

      expect(selections.to_h).to eq({ editions: %i[base_path id document_id user_facing_version] })
    end

    it "resolves field names that aren't database columns" do
      selections = GraphqlSelections.with_edition_fields(
        %i[content_id web_url],
      )

      expect(selections.to_h).to eq({
        editions: %i[base_path document_id user_facing_version],
        documents: %i[content_id],
      })
    end

    it "adds selections necessary for fetching links from the database" do
      selections = GraphqlSelections.with_edition_fields(
        %i[links],
      )

      expect(selections.to_h).to eq({
        editions: %i[id content_store document_id user_facing_version],
      })
    end

    it "does not support withrawn_notice" do
      selections = GraphqlSelections.with_edition_fields(
        %i[id withdrawn_notice],
      )

      expect(selections.to_h).to eq({ editions: %i[id document_id user_facing_version] })
    end
  end

  describe ".with_root_edition_fields" do
    it "acts like with_edition_fields but also always includes the document_type" do
      selections = GraphqlSelections.with_root_edition_fields(
        %i[id content_id],
      )

      expect(selections.to_h).to eq({
        editions: %i[id document_id user_facing_version document_type],
        documents: %i[content_id],
      })
    end

    it "supports withdrawn_notice" do
      selections = GraphqlSelections.with_root_edition_fields(
        %i[base_path withdrawn_notice],
      )

      expect(selections.to_h).to eq({
        editions: %i[base_path document_id user_facing_version document_type],
        unpublishings: [
          "created_at AS unpublishing_created_at",
          "explanation AS unpublishing_explanation",
          "type AS unpublishing_type",
          "unpublished_at AS unpublishing_unpublished_at",
        ],
      })
    end

    it "adds selections specific to fetching the root edition's links" do
      selections = GraphqlSelections.with_root_edition_fields(
        %i[links],
      )

      expect(selections.to_h).to eq({
        editions: %i[id content_store document_id user_facing_version document_type],
        documents: %i[content_id locale],
      })
    end
  end

  describe "#insert" do
    it "merges the column names with existing ones for the same table" do
      selections = GraphqlSelections.new(editions: %i[id])

      selections.insert(:editions, %i[content_store])

      expect(selections.to_h).to eq({ editions: %i[id content_store] })
    end

    it "creates entries for new tables" do
      selections = GraphqlSelections.new(editions: %i[id])

      selections.insert(:documents, %i[content_id])

      expect(selections.to_h).to eq({
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

      expect(selections.to_h).to eq({
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

  describe "#to_h" do
    it "returns a copy of the internal table and columns hash" do
      selections = GraphqlSelections.new(editions: %i[id])
      hash = selections.to_h

      expect(hash).to eq({ editions: %i[id] })
    end

    it "prevents modifying the internal table and columns hash" do
      selections = GraphqlSelections.new(editions: %i[id])
      hash = selections.to_h

      hash[:editions].push(:content_id)

      expect(hash).to eq({ editions: %i[id content_id] })
      expect(selections.to_h).to eq({ editions: [:id] })
    end
  end

  describe "ALL_EDITION_COLUMNS" do
    it "is an up-to-date list of the Edition model's database columns" do
      expect(GraphqlSelections::ALL_EDITION_COLUMNS).to match_array(
        Edition.column_names.map(&:to_sym),
      )
    end
  end
end
