require "rails_helper"

RSpec.describe Queries::BasePathForState do
  let(:conflict_base_path) { "/conflict" }
  let(:no_conflict_base_path) { "/no-conflict" }

  describe ".conflict" do
    subject { described_class.conflict(edition_id, state, base_path) }
    let(:base_path) { conflict_base_path }

    context "when content item is a draft" do
      let!(:conflict_edition) do
        FactoryGirl.create(
          :draft_edition,
          base_path: conflict_base_path,
        )
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "draft" }
      let(:collision_hash) do
        {
          id: conflict_edition.id,
          content_id: conflict_edition.content_id,
          locale: "en"
        }
      end

      context "when there is a different content id and different base path" do
        let(:base_path) { no_conflict_base_path }
        it { is_expected.to be_nil }
      end

      context "when we use this content items base path and content item id" do
        let(:edition_id) { conflict_edition.id }
        it { is_expected.to be_nil }
      end

      context "when we use this content items base path and a different content item id" do
        it "should be a collision" do
          is_expected.to match(collision_hash)
        end

        %w(published unpublished superseded).each do |state|
          context "when the content item is #{state}" do
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
      context "when content item is #{state_name}" do
        let!(:conflict_edition) do
          FactoryGirl.create(factory, base_path: conflict_base_path)
        end

        let(:edition_id) { conflict_edition.id + 1 }
        let(:state) { state_name }
        let(:collision_hash) do
          {
            id: conflict_edition.id,
            content_id: conflict_edition.content_id,
            locale: "en"
          }
        end

        context "when there is a different content id and different base path" do
          let(:base_path) { no_conflict_base_path }
          it { is_expected.to be_nil }
        end

        context "when we use this content items base path and content item id" do
          let(:edition_id) { conflict_edition.id }
          it { is_expected.to be_nil }
        end

        context "when we use this content items base path and a different content item id" do
          it "should be a collision" do
            is_expected.to match(collision_hash)
          end
        end

        context "when the item we are checking against is unpublished with type substitute" do
          let(:edition_id) do
            FactoryGirl.create(:substitute_unpublished_edition).id
          end
          let(:state) { "unpublished" }
          it { is_expected.to be_nil }
        end
      end
    end

    context "when content item is unpublished with substitute" do
      let!(:conflict_edition) do
        FactoryGirl.create(
          :substitute_unpublished_edition,
          base_path: conflict_base_path
        )
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "unpublished" }

      it { is_expected.to be_nil }
    end

    context "when content item is superseded" do
      let!(:conflict_edition) do
        FactoryGirl.create(
          :superseded_edition,
          base_path: conflict_base_path
        )
      end

      let(:edition_id) { conflict_edition.id + 1 }
      let(:state) { "superseded" }

      it { is_expected.to be_nil }
    end
  end
end
