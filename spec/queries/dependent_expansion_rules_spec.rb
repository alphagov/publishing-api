require "rails_helper"

RSpec.describe Queries::DependentExpansionRules do
  describe "#expansion_fields" do
    context "for a generic link_type" do
      let(:link_type) { :foo }

      it "returns the default fields" do
        expect(subject.expansion_fields(link_type)).to eq([
          :analytics_identifier,
          :api_path,
          :base_path,
          :content_id,
          :description,
          :document_type,
          :locale,
          :public_updated_at,
          :schema_name,
          :title,
        ])
      end
    end
  end

  describe "#recurse?" do
    specify { expect(subject.recurse?(:parent)).to eq(true) }
    specify { expect(subject.recurse?("parent")).to eq(true) }
    specify { expect(subject.recurse?(:parent_taxons)).to eq(true) }
    specify { expect(subject.recurse?(:working_groups)).to eq(false) }
    specify { expect(subject.recurse?(:documents)).to eq(false) }
    specify { expect(subject.recurse?(:foo)).to eq(false) }

    context "multi-level" do
      specify { expect(subject.recurse?(:ordered_related_items, 0)).to eq(true) }
      specify { expect(subject.recurse?(:ordered_related_items, 1)).to eq(false) }
      specify { expect(subject.recurse?(:parent, 1)).to eq(true) }
      specify { expect(subject.recurse?(:parent, 2)).to eq(true) }
      specify { expect(subject.recurse?(:parent, 3)).to eq(true) }
    end
  end

  describe "#next_level" do
    specify { expect(subject.next_level(:parent, 2)).to eq(:parent) }
    specify { expect(subject.next_level(:parent, 0)).to eq(:parent) }
    specify { expect(subject.next_level(:ordered_related_items, 0)).to eq(:ordered_related_items) }
    specify { expect(subject.next_level(:ordered_related_items, 1)).to eq(:parent) }
    specify { expect(subject.next_level(:ordered_related_items, 3)).to eq(:parent) }
  end

  describe "#reverse_name_for(link_type)" do
    specify { expect(subject.reverse_name_for(:parent)).to eq("children") }
    specify { expect(subject.reverse_name_for(:documents)).to eq("document_collections") }
    specify { expect(subject.reverse_name_for(:working_groups)).to eq("policies") }
    specify { expect(subject.reverse_name_for(:parent_taxons)).to eq("child_taxons") }
  end
end
