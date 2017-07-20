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
    specify { expect(subject.next_link_expansion_link_types([:child_taxons])).to match_array([:child_taxons, :associated_taxons]) }
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

  describe "multi-level rules" do
    let(:item) {
      FactoryGirl.build(
        :live_edition,
        document_type: "nested_doc",
        details: {
          body: "<p>Something about VAT</p>\n",
          email_signup_link: "https://public.govdelivery.com/accounts/UKGOVUK/subscriber/topics?qsp=TRAVEL",
        }
      )
    }
    let(:fields) {
      [
        :title,
        [:details, :email_signup_link]
      ]
    }
    before do
      expect(subject).to receive(:find_custom_expansion_fields).with("nested_doc", any_args).and_return fields
    end

    it "treats arrays as paths" do
      expect(subject.expand_fields(item.to_h, :children)).to include(email_signup_link: "https://public.govdelivery.com/accounts/UKGOVUK/subscriber/topics?qsp=TRAVEL")
    end

    it "uses the name of the last element of the path as the key" do
      expect(subject.expand_fields(item.to_h, :children).keys).to eq([:title, :email_signup_link])
    end

    it "does not include the top-level field itself" do
      expect(subject.expand_fields(item.to_h, :children)).not_to have_key(:details)
    end

    it "takes the first level as the potential field to use in diffs" do
      expect(subject.potential_expansion_fields("nested_doc")).to eq([:title, :details])
    end
  end

  describe "REVERSE_LINKS" do
    let(:reverse_links) { described_class::REVERSE_LINKS.values.map(&:to_s) }

    describe "are defined in necessary frontend schemas" do
      schemas_of_type("frontend/schema").each do |path, schema|
        links = schema["properties"]["links"]
        next unless links
        context "when the schema is #{path}" do
          subject { links["properties"].keys }
          it { is_expected.to include(*reverse_links) }
        end
      end
    end

    describe "are not defined in publisher schemas" do
      schemas_of_type("publisher_v2/links").each do |path, schema|
        links = schema["properties"]["links"]
        next unless links
        context "when the schema is #{path}" do
          subject { links["properties"].keys }
          it { is_expected.not_to include(*reverse_links) }
        end
      end
    end
  end
end
