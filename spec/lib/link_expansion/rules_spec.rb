require "rails_helper"

RSpec.describe LinkExpansion::Rules do
  describe ".reverse_link_type" do
    specify { expect(subject.reverse_link_type(:parent)).to be(:children) }
    specify { expect(subject.reverse_link_type(:children)).to be_nil }
    specify { expect(subject.reverse_link_type(:made_up)).to be_nil }
  end

  describe ".un_reverse_link_type" do
    specify { expect(subject.un_reverse_link_type(:children)).to be(:parent) }
    specify { expect(subject.un_reverse_link_type(:parent)).to be_nil }
    specify { expect(subject.un_reverse_link_type(:made_up)).to be_nil }
  end

  describe ".is_reverse_link_type?" do
    specify { expect(subject.is_reverse_link_type?(:children)).to be(true) }
    specify { expect(subject.is_reverse_link_type?(:parent)).to be(false) }
    specify { expect(subject.is_reverse_link_type?(:made_up)).to be(false) }
  end

  describe ".next_link_expansion_link_types" do
    # test error
    specify { expect(subject.next_link_expansion_link_types([:child_taxons])).to match_array([:child_taxons]) }
    specify { expect(subject.next_link_expansion_link_types([:parent, :parent])).to match_array([:parent]) }
    specify { expect(subject.next_link_expansion_link_types([:children])).to be_empty }
  end

  describe ".next_dependency_resolution_link_types" do
    # test error
    specify { expect(subject.next_dependency_resolution_link_types([:child_taxons])).to match_array([:child_taxons]) }
    specify { expect(subject.next_dependency_resolution_link_types([:parent])).to match_array([:parent, :mainstream_browse_pages]) }
    specify { expect(subject.next_dependency_resolution_link_types([:parent, :parent])).to match_array([:parent, :mainstream_browse_pages]) }
    specify { expect(subject.next_dependency_resolution_link_types([:parent, :children])).to be_empty }
    specify { expect(subject.next_dependency_resolution_link_types([:mainstream_browse_pages])).to match_array([:ordered_related_items]) }
    specify { expect(subject.next_dependency_resolution_link_types([:parent, :mainstream_browse_pages])).to match_array([:ordered_related_items]) }
  end

  describe ".expansion_fields" do
    let(:default_fields) { subject::DEFAULT_FIELDS }
    let(:organisation_fields) { default_fields + [:details] }
    let(:finder_fields) { default_fields + [:details] }
    specify { expect(subject.expansion_fields(:redirect)).to eq([]) }
    specify { expect(subject.expansion_fields(:parent)).to eq(default_fields) }
    specify { expect(subject.expansion_fields(:organisation)).to eq(organisation_fields) }
    specify { expect(subject.expansion_fields(:finder, :finder)).to eq(finder_fields) }
    specify { expect(subject.expansion_fields(:parent, :finder)).to eq(default_fields) }
  end
end
