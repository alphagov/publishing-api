(import "shared/default_format.jsonnet") + {
  document_type: "need",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "role",
        "goal",
        "benefit",
      ],
      properties: {
        role: {
          type: "string",
          description: "The type of user, such as a small business, a tax agent, a healthcare practitioner",
        },
        goal: {
          type: "string",
          description: "What the user wants to do",
        },
        benefit: {
          type: "string",
          description: "Why the user wants to do it",
        },
        applies_to_all_organisations: {
          type: "boolean",
          description: "Whether all linked organisations meet this need",
        },
        impact: {
          type: "string",
          description: "Impact of GOV.UK not doing this",
        },
        justifications: {
          description: "How this need fits in the proposition for GOV.UK",
          type: "array",
          items: {
            type: "string",
          },
        },
        legislation: {
          type: "string",
          description: "Legislation that underpins this need",
        },
        met_when: {
          description: "Provides criteria that define when this user need has been met",
          type: "array",
          items: {
            type: "string",
          },
        },
        other_evidence: {
          type: "string",
          description: "Any other evidence to support this need, ie. user research, campaigns, user demand",
        },
        need_id: {
          type: "string",
          description: "Six digit id which used to be the primary id for Needs. Still being displayed in Maslow and Info-Frontend, but likely to be deprecated in the future.",
        },
        yearly_need_views: {
          type: "integer",
          description: "Number of pageviews specific to this need generated each year",
        },
        yearly_searches: {
          type: "integer",
          description: "Number of searches specific to this need carried out each year",
        },
        yearly_site_views: {
          type: "integer",
          description: "Number of yearly pageviews of the whole site of the requester",
        },
        yearly_user_contacts: {
          type: "integer",
          description: "Number of user contacts received about this need each year. Includes calls to contact centres, emails, customer service tickets",
        },
      },
    },
  },
}
