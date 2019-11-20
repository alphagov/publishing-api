require "rails_helper"

RSpec.describe ExpansionRules do
  subject(:rules) { described_class }

  describe ".reverse_link_type" do
    specify { expect(rules.reverse_link_type(:parent)).to be(:children) }
    specify { expect(rules.reverse_link_type(:children)).to be_nil }
    specify { expect(rules.reverse_link_type(:made_up)).to be_nil }
  end

  describe ".reverse_to_direct_link_type" do
    specify { expect(rules.reverse_to_direct_link_type(:children)).to match_array(%i(parent)) }
    specify { expect(rules.reverse_to_direct_link_type(:role_appointments)).to match_array(%i(role person)) }
    specify { expect(rules.reverse_to_direct_link_type(:parent)).to be_empty }
    specify { expect(rules.reverse_to_direct_link_type(:made_up)).to be_empty }
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
    let(:taxon_fields) { default_fields + %i(description details phase) }
    let(:mainstream_browser_page_fields) { default_fields + %i(description) }
    let(:need_fields) { default_fields + [%i(details role), %i(details goal), %i(details benefit), %i(details met_when), %i(details justifications)] }
    let(:finder_fields) { default_fields + [%i(details facets)] }
    let(:role_fields) { default_fields + [%i(details body)] }
    let(:role_appointment_fields) { default_fields + [%i(details started_on), %i(details ended_on), %i(details current), %i(details person_appointment_order)] }
    let(:service_manual_topic_fields) { default_fields + %i(description) }
    let(:step_by_step_fields) { default_fields + [%i(details step_by_step_nav title), %i(details step_by_step_nav steps)] }
    let(:step_by_step_auth_bypass_fields) { step_by_step_fields + %i(auth_bypass_ids) }
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
        short_name
        type
      ].map { |key| [:details, key] }
    end

    specify { expect(rules.expansion_fields(:redirect)).to eq([]) }
    specify { expect(rules.expansion_fields(:gone)).to eq([]) }

    specify { expect(rules.expansion_fields(:parent)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:contact)).to eq(contact_fields) }
    specify { expect(rules.expansion_fields(:mainstream_browse_page)).to eq(mainstream_browser_page_fields) }
    specify { expect(rules.expansion_fields(:need)).to eq(need_fields) }
    specify { expect(rules.expansion_fields(:organisation)).to eq(organisation_fields) }
    specify { expect(rules.expansion_fields(:placeholder_organisation)).to eq(organisation_fields) }
    specify { expect(rules.expansion_fields(:placeholder_topical_event)).to eq(default_fields) }
    specify { expect(rules.expansion_fields(:role_appointment)).to eq(role_appointment_fields) }
    specify { expect(rules.expansion_fields(:service_manual_topic)).to eq(service_manual_topic_fields) }
    specify { expect(rules.expansion_fields(:topical_event)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:ambassador_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:board_member_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:chief_professional_officer_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:chief_scientific_advisor_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:chief_scientific_officer_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:deputy_head_of_mission_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:governor_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:high_commissioner_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:military_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:ministerial_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:special_representative_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:traffic_commissioner_role)).to eq(role_fields) }
    specify { expect(rules.expansion_fields(:worldwide_office_staff_role)).to eq(role_fields) }

    specify { expect(rules.expansion_fields(:step_by_step_nav, link_type: :part_of_step_navs)).to eq(step_by_step_auth_bypass_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav, link_type: :part_of_step_navs, draft: false)).to eq(step_by_step_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav, link_type: :related_to_step_navs)).to eq(step_by_step_auth_bypass_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav, link_type: :related_to_step_navs, draft: false)).to eq(step_by_step_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav, link_type: :unspecified_link)).to eq(step_by_step_fields) }
    specify { expect(rules.expansion_fields(:step_by_step_nav)).to eq(step_by_step_auth_bypass_fields) }

    specify { expect(rules.expansion_fields(:taxon)).to eq(taxon_fields) }
    specify { expect(rules.expansion_fields(:travel_advice)).to eq(travel_advice_fields) }
    specify { expect(rules.expansion_fields(:world_location)).to eq(world_location_fields) }

    specify { expect(rules.expansion_fields(:finder, link_type: :finder)).to eq(finder_fields) }
    specify { expect(rules.expansion_fields(:parent, link_type: :finder)).to eq(default_fields) }

    specify { expect(rules.expansion_fields(:facet_group)).to eq(facet_group_fields) }
    specify { expect(rules.expansion_fields(:facet)).to eq(facet_fields) }
    specify { expect(rules.expansion_fields(:facet_value)).to eq(facet_value_fields) }
  end

  describe ".expansion_fields_for_document_type" do
    before do
      stub_const(
        "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
        [
          { document_type: :news, fields: %i[news_a] },
          { document_type: :news,
            link_type: :breaking_news,
            fields: %i[news_a news_b] },
          { document_type: :news,
            link_type: :local_news,
            fields: %i[news_c news_d] },
        ],
      )
    end

    it "returns default fields when a document type doesn't have any custom entries" do
      expect(rules.expansion_fields_for_document_type(:other_type))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "can accept a string instead of a symbol" do
      from_symbol = rules.expansion_fields_for_document_type(:news)
      from_string = rules.expansion_fields_for_document_type("news")
      expect(from_symbol).to eq(from_string)
    end

    it "collates all the fields used by links for the document type" do
      expect(rules.expansion_fields_for_document_type(:news))
        .to match_array(%i[news_a news_b news_c news_d])
    end

    context "when a custom fields entry only has examples with links" do
      before do
        stub_const(
          "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
          [
            { document_type: :editorial,
              link_type: :current_events,
              fields: %i[editorial_a] },
            { document_type: :editorial,
              link_type: :world_events,
              fields: %i[editorial_b] },
          ],
        )
      end

      it "includes default fields as expansion fields" do
        expect(rules.expansion_fields_for_document_type(:editorial))
          .to contain_exactly(:editorial_a, :editorial_b, *ExpansionRules::DEFAULT_FIELDS)
      end
    end
  end

  describe ".expansion_fields_for_linked_document_type" do
    before do
      stub_const(
        "ExpansionRules::CUSTOM_EXPANSION_FIELDS",
        [
          { document_type: :news, fields: %i[news_a] },
          { document_type: :news,
            link_type: :breaking_news,
            fields: %i[news_a news_b] },
          { document_type: :editorial,
            link_type: :current_events,
            fields: %i[editorial_a] },
        ],
      )
    end

    it "can accept strings instead of symbols" do
      from_symbols = rules.expansion_fields_for_linked_document_type(:news, :breaking_news)
      from_strings = rules.expansion_fields_for_linked_document_type("news", "breaking_news")
      expect(from_symbols).to eq(from_strings)
    end

    it "returns default fields when a document type doesn't have any custom entries" do
      expect(rules.expansion_fields_for_linked_document_type(:unknown_type, :unknown_link))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "returns default fields when a document type is only listed for specific links" do
      expect(rules.expansion_fields_for_linked_document_type(:editorial, :unknown_link))
        .to match_array(ExpansionRules::DEFAULT_FIELDS)
    end

    it "returns specified fields when document type and link type match" do
      expect(rules.expansion_fields_for_linked_document_type(:news, :breaking_news))
        .to match_array(%i[news_a news_b])
    end

    it "returns specified fields when link type is not matched but "\
      "document_type is defined without a link type" do
      expect(rules.expansion_fields_for_linked_document_type(:news, :unknown_type))
        .to match_array(%i[news_a])
    end
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

    context "when reverse_to_direct is true and passed a reverse link with multiple direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          role_appointments: [:other],
        }
      end

      it "reverses the link type" do
        is_expected.to match(
          person: [:other],
          role: [:other],
        )
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

    context "when reverse_to_direct is true and passed a reverse link with multiple direct links" do
      let(:reverse_to_direct) { true }
      let(:next_allowed_link_types) do
        {
          other: [:role_appointments],
        }
      end

      it "changes the link types to be their direct counterpart" do
        is_expected.to match(other: %i(person role))
      end
    end
  end

  describe "REVERSE_LINKS" do
    let(:reverse_links) { described_class.reverse_links.map(&:to_s) }

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
          },
        }
      end

      it "expands into a new details hash" do
        expect(described_class.expand_fields(edition_hash)).to eq(
          document_type: "travel_advice",
          details: {
            country: "fr",
            change_description: nil,
          },
          analytics_identifier: nil,
          api_path: nil,
          base_path: nil,
          content_id: nil,
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
