(import "shared/default_format.jsonnet") + {
  document_type: "ministers_index",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      optional: ['reshuffle'],
      properties: {
        reshuffle: {
          message: "string",
        },
        body: {
          description: "The main text to show on the page",
          type: "string",
        }
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    ordered_cabinet_ministers: {
      description: "Links to the current cabinet ministers in the correct order"
    },
    ordered_also_attends_cabinet: {
      description: "Links to the current ministers without a cabinet position who also attend cabinet in the correct order"
    },
    ordered_ministerial_departments: {
      description: "Links to the ministerial department organisations in the correct order"
    },
    ordered_house_of_commons_whips: {
      description: "Links to the current House of Commons whips in the correct order"
    },
    ordered_junior_lords_of_the_treasury_whips: {
      description: "Links to the current Junior Lords of the Treasury whips in the correct order"
    },
    ordered_assistant_whips: {
      description: "Links to the current assistant whips in the correct order"
    },
    ordered_house_lords_whips: {
      description: "Links to the current House of Lords whips in the correct order"
    },
    ordered_baronessess_and_ladies_in_waiting_whips: {
      description: "Links to the current Baroness and Ladies in Waiting whips in the correct order"
    },
    ordered_baronesses_and_lords_in_waiting_whips: {
      description: "Links to the current Baronesses and Lords in Waiting whips in the correct order"
    }
  }
}
