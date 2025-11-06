RSpec.describe "Requesting live content by base path" do
  schema_specific_fields = {
    call_for_evidence: { details: { body: "", political: false } },
    case_study: { details: { body: "" } },
    consultation: { details: { body: "", political: false } },
    document_collection: { details: { collection_groups: [], political: false } },
    embassies_index: { details: { world_locations: [] } },
    fatality_notice: {
      details: {
        body: "",
        change_history: [],
        emphasised_organisations: [],
        roll_call_introduction: "",
      },
    },
    finder_email_signup: { details: { subscription_list_title_prefix: "" } },
    historic_appointment: { details: { body: "", political_party: "" } },
    historic_appointments: {
      details: { appointments_without_historical_accounts: [] },
    },
    hmrc_manual: { details: { child_section_groups: [] } },
    hmrc_manual_section: {
      details: {
        manual: { base_path: "/abc" },
        section_id: "",
      },
    },
    how_government_works: { details: { reshuffle_in_progress: false } },
    manual: { details: { body: "" } },
    manual_section: {
      details: {
        body: "",
        manual: { base_path: "/abc" },
        organisations: [],
      },
    },
    news_article: { details: { body: "" } },
    simple_smart_answer: { details: { start_button_text: "" } },
    specialist_document: { details: { body: "", metadata: {} } },
    speech: {
      details: {
        body: "",
        delivered_on: "2016-05-12T12:30:00+00:00",
        political: false,
      },
    },
    statistical_data_set: { details: { body: "", political: false } },
    statistics_announcement: {
      details: {
        display_date: "January 2016",
        format_sub_type: "national",
        state: "cancelled",
      },
    },
    step_by_step_nav: {
      details: {
        step_by_step_nav: {
          title: "",
          introduction: "",
          steps: [],
        },
      },
    },
    topical_event_about_page: { details: { body: "", read_more: "" } },
    travel_advice: {
      details: {
        alert_status: [],
        change_description: "",
        country: { slug: "", name: "" },
        email_signup_link: "",
        parts: [],
        reviewed_at: "2025-07-16T15:26:34Z",
        updated_at: "2025-09-05T08:15:33Z",
      },
    },
    travel_advice_index: { details: { email_signup_link: "" } },
    world_index: {
      details: { world_locations: [], international_delegations: [] },
    },
    world_location_news: {
      details: {
        mission_statement: "",
        ordered_featured_documents: [],
        ordered_featured_links: [],
      },
    },
  }

  Dir.children(Rails.root.join("app/graphql/queries")).each do |query_filename|
    schema_name = query_filename.split(".").first

    context "when the edition is a #{schema_name}" do
      # NOTE: this should not be taken as evidence that we produce a valid
      # response for real data. We can't guarantee that the factory-generated
      # edition looks like real data, so this won't catch certain issues
      it "can produce a response that is valid against the schema" do
        schema = GovukSchemas::Schema.find(frontend_schema: schema_name)
        document_type = schema.dig("properties", "document_type", "enum").sample
        edition = create(
          :live_edition,
          schema_name:,
          document_type:,
          **schema_specific_fields.fetch(schema_name.to_sym, {}),
        )

        get "/graphql/content/#{edition.base_path}"

        parsed_response = JSON.parse(response.body)
        errors = JSON::Validator.fully_validate(schema, parsed_response)

        expect(errors).to eql([]), errors.join("\n")
      end
    end
  end
end
