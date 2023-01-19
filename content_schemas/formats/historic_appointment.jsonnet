(import "shared/default_format.jsonnet") + {
  document_type: [
    "historic_appointment"
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "political_party",
      ],
      properties: {
        body: {
          description: "The main content provided as HTML rendered from govspeak",
          type: "string"
        },
        born: {
          description: "String containing the year of birth",
          type: "string"
        },
        died: {
          description: "String containing the date of death",
          type: "string"
        },
        interesting_facts: {
          description: "String containing interesting facts about the office holder",
          type: "string"
        },
        major_acts: {
          description: "String containing major acts implemented by the office holder",
          type: "string"
        },
        political_party: {
          description: "String containing the political party of the office holder",
          type: "string"
        },
        previous_dates_in_office: {
          description: "String containing the previous dates in office",
          type: "string"
        }
      },
    },
    links: (import "shared/base_links.jsonnet") + {
      person: "The person who is represented by this historic appointment",
    },
  },
}
