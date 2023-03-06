(import "shared/default_format.jsonnet") + {
  document_type: [
    "how_government_works"
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        department_counts: {
          description: "Number of departments by type",
          type: "object",
          properties: {
            ministerial_departments: {
              description: "Number of ministerial departments",
              type: "integer",
            },
            non_ministerial_departments: {
              description: "Number of non-ministerial departments",
              type: "integer",
            },
            agencies_and_public_bodies: {
              description: "Number of agencies and public bodies",
              type: "integer",
            }
          },
          required: [
            "ministerial_departments",
            "non_ministerial_departments",
            "agencies_and_public_bodies",
          ],
        },
        ministerial_role_counts: {
          description: "Number of ministerial role appointments by type",
          type: "object",
          properties: {
            prime_minister: {
              description: "Number of current people in the prime minister role",
              type: "integer",
            },
            cabinet_ministers: {
              description: "Number of current people in cabinet roles",
              type: "integer",
            },
            other_ministers: {
              description: "Number of current people in non-cabinet ministerial roles",
              type: "integer",
            },
            total_ministers: {
              description: "Number of current ministers",
              type: "integer",
            }
          },
          required: [
            "prime_minister",
            "cabinet_ministers",
            "other_ministers",
            "total_ministers",
          ],
        },
        reshuffle_in_progress: {
          description: "Boolean as to whether there is a ministerial reshuffle taking place",
          type: "boolean",
        }
      },
      required: [
        "reshuffle_in_progress"
      ],
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    current_prime_minister: {
        description: "Link to the person page for the current prime minister"
    },
  },
}
