require "rails_helper"

RSpec.describe ExpansionRules do
  subject(:rules) { described_class }

  describe ".reverse_link_type" do
    specify { expect(rules.reverse_link_type(:parent)).to be(:children) }
    specify { expect(rules.reverse_link_type(:children)).to be_nil }
    specify { expect(rules.reverse_link_type(:made_up)).to be_nil }
  end

  describe ".reverse_to_direct_link_type" do
    specify { expect(rules.reverse_to_direct_link_type(:children)).to be(:parent) }
    specify { expect(rules.reverse_to_direct_link_type(:parent)).to be_nil }
    specify { expect(rules.reverse_to_direct_link_type(:made_up)).to be_nil }
  end

  describe ".is_reverse_link_type?" do
    specify { expect(rules.is_reverse_link_type?(:children)).to be(true) }
    specify { expect(rules.is_reverse_link_type?(:parent)).to be(false) }
    specify { expect(rules.is_reverse_link_type?(:made_up)).to be(false) }
  end

  describe ".reverse_to_direct_link_types" do
    specify do
      expect(rules.reverse_to_direct_link_types(%i[children documents]))
        .to match([:parent])
    end
    specify { expect(rules.reverse_to_direct_link_types([:made_up])).to match([]) }
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
    let(:contact_fields) { default_fields + [%i(details description), %i(details title), %i(details contact_form_links), %i(details post_addresses), %i(details email_addresses), %i(details phone_numbers)] }
    let(:organisation_fields) { default_fields - [:public_updated_at] + [%i(details logo), %i(details brand), %i(details default_news_image)] }
    let(:taxon_fields) { default_fields + %i(details phase) }
    let(:need_fields) { default_fields + [%i(details role), %i(details goal), %i(details benefit), %i(details met_when), %i(details justifications)] }
    let(:finder_fields) { default_fields + [%i(details facets)] }
    let(:step_by_step_fields) { default_fields + [%i(details step_by_step_nav title), %i(details step_by_step_nav steps)] }
    let(:travel_advice_fields) { default_fields + [%i(details country), %i(details change_description)] }
    let(:world_location_fields) { %i(content_id title schema_name locale analytics_identifier) }
    let(:facet_group_fields) { %i(content_id title locale schema_name) + [%i(details name), %i(details description)] }
    let(:facet_fields) { %i(content_id title locale schema_name) + facet_details_fields }
    let(:facet_value_fields) { %i(content_id title locale schema_name) + [%i(details label), %i(details value)] }
    let(:facet_details_fields) do
      %i[
        combine_mode
        display_as_result_metadata
        filterable
        filter_key
        key
        name
        preposition
        type
      ].map { |key| [:details, key] }
    end

    specify { expect(rules.expansion_fields(:redirect)).to eq([]) }
    specify { expect(rules.expansion_fields(:gone)).to eq([]) }

    specify { expect(rules.expansion_fields(:parent)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:contact)).to eq(contact_fields) }
    specify { expect(rules.expansion_fields(:need)).to eq(need_fields) }
    specify { expect(rules.expansion_fields(:organisation)).to eq(organisation_fields) }
    specify { expect(rules.expansion_fields(:placeholder_organisation)).to eq(organisation_fields) }
    specify { expect(rules.expansion_fields(:placeholder_topical_event)).to eq(default_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav)).to eq(step_by_step_fields) }
    specify { expect(rules.expansion_fields(:topical_event)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:taxon)).to eq(taxon_fields) }
    specify { expect(rules.expansion_fields(:travel_advice)).to eq(travel_advice_fields) }
    specify { expect(rules.expansion_fields(:world_location)).to eq(world_location_fields) }

    specify { expect(rules.expansion_fields(:finder, :finder)).to eq(finder_fields) }
    specify { expect(rules.expansion_fields(:parent, :finder)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:facet_group)).to eq(facet_group_fields) }
    specify { expect(rules.expansion_fields(:facet)).to eq(facet_fields) }
    specify { expect(rules.expansion_fields(:facet_value)).to eq(facet_value_fields) }
  end

  describe ".next_allowed_direct_link_types" do
    let(:reverse_to_direct) { false }
    subject do
      described_class.next_allowed_direct_link_types(
        next_allowed_link_types, reverse_to_direct: reverse_to_direct
      )
    end

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          parent: %i[parent parent_taxons],
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
          parent: %i[children parent],
        }
      end

      it "returns the direct links" do
        is_expected.to match(parent: [:parent])
      end
    end

    context "when passed a reverse link with direct links" do
      let(:next_allowed_link_types) do
        {
          children: [:parent],
        }
      end

      it "returns the direct links" do
        is_expected.to match(children: [:parent])
      end
    end

    context "when reverse_to_direct is true and passed a reverse link with direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          children: [:parent],
        }
      end

      it "reverses the link type" do
        is_expected.to match(parent: [:parent])
      end
    end
  end

  describe ".next_allowed_reverse_link_types" do
    let(:reverse_to_direct) { false }
    subject do
      described_class.next_allowed_reverse_link_types(
        next_allowed_link_types,
        reverse_to_direct: reverse_to_direct,
      )
    end

    context "when passed direct links only" do
      let(:next_allowed_link_types) do
        {
          children: %i[parent parent_taxons],
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
          children: %i[children parent],
        }
      end

      it "returns the reverse links" do
        is_expected.to match(children: [:children])
      end
    end

    context "when reverse_to_direct is true" do
      let(:next_allowed_link_types) do
        {
          children: [:children],
        }
      end
      let(:reverse_to_direct) { true }

      it "changes the link types to be their direct counterpart" do
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

  describe ".expand_fields" do
    context "with a format that expands subfields of the details hash" do
      let(:edition_hash) do
        {
          document_type: "travel_advice",
          details: {
            country: "fr",
            other_field: "test",
          }
        }
      end

      it "expands into a new details hash" do
        expect(described_class.expand_fields(edition_hash, nil)).to eq(
          document_type: "travel_advice",
          details: {
            country: "fr",
            change_description: nil,
          },
          analytics_identifier: nil,
          api_path: nil,
          base_path: nil,
          content_id: nil,
          description: nil,
          locale: nil,
          public_updated_at: nil,
          schema_name: nil,
          title: nil,
          withdrawn: nil,
        )
      end
    end
  end
end
