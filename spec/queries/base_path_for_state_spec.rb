RSpec.describe Queries::BasePathForState do
  let(:conflict_base_path) { "/conflict" }
  let(:no_conflict_base_path) { "/no-conflict" }

  describe ".conflict" do
    subject { described_class.conflict(edition_id, state, base_path) }
    let(:base_path) { conflict_base_path }

    context "when edition is a draft" do
      let!(:conflict_edition) do
        create(:draft_edition, base_path: conflict_base_path)
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "draft" }
      let(:collision_hash) do
        {
          id: conflict_edition.id,
          content_id: conflict_edition.document.content_id,
          locale: "en",
        }
      end

      context "when there is a different content id and different base path" do
        let(:base_path) { no_conflict_base_path }
        it { is_expected.to be_nil }
      end

      context "when we use this editions base path and edition id" do
        let(:edition_id) { conflict_edition.id }
        it { is_expected.to be_nil }
      end

      context "when we use this editions base path and a different edition id" do
        it "should be a collision" do
          is_expected.to match(collision_hash)
        end

        %w[published unpublished superseded].each do |state|
          context "when the edition is #{state}" do
            before do
              conflict_edition.update(state: state)
            end

            it { is_expected.to be_nil }
          end
        end
      end
    end

    {
      "published" => :live_edition,
      "unpublished" => :unpublished_edition,
    }.each do |state_name, factory|
      context "when edition is #{state_name}" do
        let!(:conflict_edition) do
          create(factory, base_path: conflict_base_path)
        end

        let(:edition_id) { conflict_edition.id + 1 }
        let(:state) { state_name }
        let(:collision_hash) do
          {
            id: conflict_edition.id,
            content_id: conflict_edition.document.content_id,
            locale: "en",
          }
        end

        context "when there is a different content id and different base path" do
          let(:base_path) { no_conflict_base_path }
          it { is_expected.to be_nil }
        end

        context "when we use this editions base path and edition id" do
          let(:edition_id) { conflict_edition.id }
          it { is_expected.to be_nil }
        end

        context "when we use this editions base path and a different edition id" do
          it "should be a collision" do
            is_expected.to match(collision_hash)
          end
        end

        context "when the item we are checking against is unpublished with type substitute" do
          let(:edition_id) do
            create(:substitute_unpublished_edition).id
          end
          let(:state) { "unpublished" }
          it { is_expected.to be_nil }
        end
      end
    end

    context "when edition is unpublished with substitute" do
      let!(:conflict_edition) do
        create(
          :substitute_unpublished_edition,
          base_path: conflict_base_path,
        )
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "unpublished" }

      it { is_expected.to be_nil }
    end

    context "when edition is superseded" do
      let!(:conflict_edition) do
        create(
          :superseded_edition,
          base_path: conflict_base_path,
        )
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "superseded" }

      it { is_expected.to be_nil }
    end
  end
end
