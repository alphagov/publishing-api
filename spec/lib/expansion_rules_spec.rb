require "rails_helper"

RSpec.describe ExpansionRules do
  subject(:rules) { described_class }

  describe ".reverse_link_type" do
    specify { expect(rules.reverse_link_type(:parent)).to be(:children) }
    specify { expect(rules.reverse_link_type(:children)).to be_nil }
    specify { expect(rules.reverse_link_type(:made_up)).to be_nil }
  end

  describe ".unreverse_link_type" do
    specify { expect(rules.unreverse_link_type(:children)).to be(:parent) }
    specify { expect(rules.unreverse_link_type(:parent)).to be_nil }
    specify { expect(rules.unreverse_link_type(:made_up)).to be_nil }
  end

  describe ".is_reverse_link_type?" do
    specify { expect(rules.is_reverse_link_type?(:children)).to be(true) }
    specify { expect(rules.is_reverse_link_type?(:parent)).to be(false) }
    specify { expect(rules.is_reverse_link_type?(:made_up)).to be(false) }
  end

  describe ".unreverse_link_types" do
    specify do
      expect(rules.unreverse_link_types([:children, :documents]))
        .to match([:parent])
    end
    specify { expect(rules.unreverse_link_types([:made_up])).to match([]) }
  end

  describe ".reverse_link_types_hash" do
    let(:content_ids) { %w(a b) }
    specify do
      expect(rules.reverse_link_types_hash(parent: content_ids))
        .to match(children: content_ids)
      expect(rules.reverse_link_types_hash(policies: content_ids)).to match({})
    end
  end

  describe ".expansion_fields" do
    let(:default_fields) { rules::DEFAULT_FIELDS }
    let(:organisation_fields) { default_fields + [:details] }
    let(:finder_fields) { default_fields + [:details] }
    specify { expect(rules.expansion_fields(:redirect)).to eq([]) }
    specify { expect(rules.expansion_fields(:parent)).to eq(default_fields) }
    specify { expect(rules.expansion_fields(:organisation)).to eq(organisation_fields) }
    specify { expect(rules.expansion_fields(:finder, :finder)).to eq(finder_fields) }
    specify { expect(rules.expansion_fields(:parent, :finder)).to eq(default_fields) }
  end

  describe ".next_allowed_direct_link_types" do
    subject do
      described_class.next_allowed_direct_link_types(next_allowed_link_types)
    end

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          parent: [:parent, :parent_taxons],
        }
      end

      it "returns the links unchanged" do
        is_expected.to match(next_allowed_link_types)
      end
    end

    context "when passed reverse links only" do
      let(:next_allowed_link_types) do
        {
          parent: [:children],
        }
      end

      it "returns an empty hash" do
        is_expected.to be_empty
      end
    end

    context "when passed a mixture of direct and reverse links" do
      let(:next_allowed_link_types) do
        {
          parent: [:children, :parent],
        }
      end

      it "returns the direct links" do
        is_expected.to match(parent: [:parent])
      end
    end
  end

  describe ".next_allowed_reverse_link_types" do
    let(:unreverse) { false }
    subject do
      described_class.next_allowed_reverse_link_types(
        next_allowed_link_types,
        unreverse: unreverse,
      )
    end

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          children: [:parent, :parent_taxons],
        }
      end

      it "returns an empty hash" do
        is_expected.to be_empty
      end
    end

    context "when passed reverse links only" do
      let(:next_allowed_link_types) do
        {
          children: [:children],
        }
      end

      it "returns the links unchanged" do
        is_expected.to match(next_allowed_link_types)
      end
    end

    context "when passed a mixture of direct and reverse links" do
      let(:next_allowed_link_types) do
        {
          children: [:children, :parent],
        }
      end

      it "returns the reverse links" do
        is_expected.to match(children: [:children])
      end
    end

    context "when unreverse is true" do
      let(:next_allowed_link_types) do
        {
          children: [:children],
        }
      end
      let(:unreverse) { true }

      it "unreverses the link types to be their direct counterpart" do
        is_expected.to match(parent: [:parent])
      end
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
