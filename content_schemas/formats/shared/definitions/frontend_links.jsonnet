{
  frontend_links: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: true,
      required: [
        "content_id",
        "locale",
        "title",
      ],
      properties: {
        document_type: {
          type: "string",
        },
        schema_name: {
          type: "string",
        },
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_url: {
          description: "DEPRECATED: api_path should be used instead of api_url. This is due to values of api_url being tied to an environment which can cause problems when data is synced between environments. In time this field will be removed by the Publishing Platform team.",
          type: "string",
          format: "uri",
        },
        web_url: {
          description: "DEPRECATED: base_path should be used instead of web_url. This is due to values of web_url being tied to an environment which can cause problems when data is synced between environments. In time this field will be removed by the Publishing Platform team.",
          type: "string",
          format: "uri",
        },
        analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        public_updated_at: {
          oneOf: [
            { "$ref": "#/definitions/public_updated_at" },
            { type: "null" },
          ],
        },
        content_id: {
          "$ref": "#/definitions/guid",
        },
        title: {
          type: "string",
        },
        locale: {
          "$ref": "#/definitions/locale",
        },
        links: {
          type: "object",
          patternProperties: {
            "^[a-z_]+$": {
              "$ref": "#/definitions/frontend_links",
            }
          }
        },
      },
    },
  },
  frontend_links_with_base_path: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: true,
      required: [
        "base_path",
        "content_id",
        "locale",
        "title",
      ],
      properties: {
        document_type: {
          type: "string",
        },
        schema_name: {
          type: "string",
        },
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_path: {
          "$ref": "#/definitions/absolute_path",
        },
        api_url: {
          description: "DEPRECATED: api_path should be used instead of api_url. This is due to values of api_url being tied to an environment which can cause problems when data is synced between environments. In time this field will be removed by the Publishing Platform team.",
          type: "string",
          format: "uri",
        },
        web_url: {
          description: "DEPRECATED: base_path should be used instead of web_url. This is due to values of web_url being tied to an environment which can cause problems when data is synced between environments. In time this field will be removed by the Publishing Platform team.",
          type: "string",
          format: "uri",
        },
        analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        public_updated_at: {
          oneOf: [
            { "$ref": "#/definitions/public_updated_at" },
            { type: "null" },
          ],
        },
        content_id: {
          "$ref": "#/definitions/guid",
        },
        title: {
          type: "string",
        },
        locale: {
          "$ref": "#/definitions/locale",
        },
        links: {
          type: "object",
          patternProperties: {
            "^[a-z_]+$": {
              "$ref": "#/definitions/frontend_links_with_base_path",
            }
          }
        },
      },
    },
  },
}
