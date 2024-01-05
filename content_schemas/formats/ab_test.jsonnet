(import "shared/default_format.jsonnet") + {
  document_type: "ab_test",
  base_path: "forbidden",
  routes: "forbidden",
  description: "required",
  rendering_app: "forbidden",
  edition_links: {},
  links: {},
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "name",
        "placeholder",
        "dimension",
        "variants",
        "default_variant",
      ],
      properties: {
        name: {
          description: "The name of the AB test in UpperCamelCase",
          type: "string",
          pattern: "^[A-Z][a-zA-Z]+$",
        },
        placeholder: {
          description: "The string to replace in linked content items, for example {{ab_test_example}}",
          type: "string",
          pattern: "^\\{\\{[a-z_]+\\}\\}$"
        },
        dimension: {
          description: "The google analytics dimension to use for the AB test",
          type: "number",
        },
        variants: {
          description: "The HTML content to replace the placeholder with in each variant (usually A, B, Z)",
          type: "object",
          patternProperties: {
            "^[A-Z]$": {type: "string"},
          }
        },
        default_variant: {
          description: "The name of the default variant to use (usually Z)",
          type: "string",
          pattern: "^[A-Z]$"
        }
      },
    },
  },

}
