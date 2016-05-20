require "rails_helper"

RSpec.describe Queries::ContentDependencies do
  let(:parent_content_item) { FactoryGirl.create(:content_item, base_path: "/tax") }
  let(:child_content_item) { FactoryGirl.create(:content_item, base_path: "/vat-rates") }
  let(:special_content_item) { FactoryGirl.create(:content_item, base_path: "/something-special") }

  let(:link_set) { FactoryGirl.create(:link_set, content_id: child_content_item.content_id) }

  let!(:link) {
    FactoryGirl.create(:link,
      link_set: link_set,
      link_type: 'special',
      target_content_id: special_content_item.content_id,
    )
  }
  let!(:link_2) {
    FactoryGirl.create(:link,
      link_set: link_set,
      link_type: 'parent',
      target_content_id: parent_content_item.content_id,
    )
  }

  describe "dependent lookups" do
    subject(:dependents) do
      described_class.new(
        content_id: parent_content_item.content_id,
        fields: fields,
        direction: :dependents,
      )
    end

    context "link_sets" do
      let(:fields) { [:base_path] }

      it "calculates the correct link_types" do
        expect_any_instance_of(Queries::GetDependents).to receive(:call).with(
          content_id: parent_content_item.content_id,
          recursive_link_types: %w(parent),
          direct_link_types: [],
        )
        dependents.call
      end
    end

    context "field changes that require dependent lookup" do
      let(:fields) { [:base_path, :other_field] }
      it "returns the dependents" do
        expect(dependents.call).to match_array([child_content_item.content_id])
      end
    end

    context "field changes that do not require dependent lookup" do
      let(:fields) { [:foo] }
      it "returns no dependents" do
        expect(dependents.call).to eq([])
      end
    end
  end

  describe "dependee lookups" do
    subject(:dependees) do
      described_class.new(
        content_id: child_content_item.content_id,
        fields: fields,
        direction: :dependees,
      )
    end

    context "link_sets" do
      let(:fields) { [:base_path] }

      it "calculates the correct link_types" do
        expect_any_instance_of(Queries::GetDependees).to receive(:call).with(
          content_id: child_content_item.content_id,
          recursive_link_types: %w(parent),
          direct_link_types: %w(special)
        )
        dependees.call
      end
    end

    context "field changes that require dependee lookup" do
      let(:fields) { [:base_path, :other_field] }
      it "returns the dependees" do
        expect(dependees.call).to match_array([
          special_content_item.content_id,
          parent_content_item.content_id,
        ])
      end
    end

    context "field changes that do not require dependee lookup" do
      let(:fields) { [:foo] }
      it "returns no dependees" do
        expect(dependees.call).to eq([])
      end
    end
  end
end
