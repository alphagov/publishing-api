{
  government: {
    type: "object",
    additionalProperties: false,
    description: "DEPRECATED: Content should be associated with a government through a link",
    required: [
      "title",
      "slug",
      "current",
    ],
    properties: {
      title: {
        type: "string",
        description: "Name of the government that first published this document, eg '1970 to 1974 Conservative government'.",
      },
      slug: {
        type: "string",
        description: "Government slug, used for analytics, eg '1970-to-1974-conservative-government'.",
      },
      current: {
        type: "boolean",
        description: "Is the government that published this document still the current government.",
      },
    },
  },
  image: {
    type: "object",
    additionalProperties: false,
    required: [
      "url",
    ],
    properties: {
      url: {
        description: "URL to the image. The image should be in a suitable resolution for display on the page.",
        type: "string",
        format: "uri",
      },
      high_resolution_url: {
        description: "URL to a high resolution version of the image, for use by third parties such as Twitter, Facebook or Slack. Used by the machine readable metadata component. Don't use this on user-facing web pages, as it might be very large.",
        type: "string",
        format: "uri",
      },
      alt_text: {
        type: "string",
      },
      caption: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
      credit: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
    },
  },
  summary_organisations: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
        "separate_website",
        "format",
        "slug",
        "content_id",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
        brand: {
          type: [
            "string",
            "null",
          ],
        },
        logo: {
          type: "object",
          properties: {
            type_class_name: {
              type: "string",
            },
            formatted_title: {
              type: "string",
            },
            crest: {
              type: [
                "string",
                "null",
              ],
              enum: [
                "bis",
                "dit",
                "eo",
                "hmrc",
                "ho",
                "mod",
                "portcullis",
                "single-identity",
                "so",
                "ukaea",
                "wales",
                null,
              ],
            },
            image: {
              "$ref": "#/definitions/image",
            },
          },
        },
        separate_website: {
          type: "boolean",
        },
        format: {
          type: "string"
        },
        updated_at: {
          type: "string",
          format: "date-time",
        },
        slug: {
          type: "string"
        },
        acronym: {
          type: [
            "string",
            "null",
          ],
        },
        brand_colour_class: {
          type: "string",
        },
        closed_at: {
          type: [
            "string",
            "null",
          ],
        },
        govuk_status: {
          type: [
            "string",
            "null",
          ],
        },
        govuk_closed_status: {
          type: [
            "string",
            "null",
          ],
        },
        content_id: {
          "$ref": "#/definitions/guid",
        },
        analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        parent_organisations: {
          "$ref": "#/definitions/list_of_sub_organisations",
        },
        child_organisations: {
          "$ref": "#/definitions/list_of_sub_organisations",
        },
        superseded_organisations: {
          "$ref": "#/definitions/list_of_sub_organisations",
        },
        superseding_organisations: {
          "$ref": "#/definitions/list_of_sub_organisations",
        },
        works_with: {
          type: "object",
          additionalProperties: false,
          properties: {
            adhoc_advisory_group: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            advisory_ndpb: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            civil_service: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            devolved_administration: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            executive_agency: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            executive_ndpb: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            executive_office: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            independent_monitoring_body: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            ministerial_department: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            non_ministerial_department: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            other: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            public_corporation: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            special_health_authority: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            sub_organisation: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
            tribunal: {
              "$ref": "#/definitions/list_of_sub_organisations",
            },
          },
        },
      },
    },
    description: "A list of all organisations of a particular type. Turn into proper links once details for organisations no longer need to be expanded.",
  },
  list_of_sub_organisations: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
      },
    },
    description: "A list of all sub-organisations of a particular type for a parent organisation. Turn into proper links once details for organisations no longer need to be expanded.",
  },
  political: {
    type: "boolean",
    description: "If the content is considered political in nature, reflecting views of the government it was published under.",
  },
  emphasised_organisations: {
    description: "The content ids of the organisations that should be displayed first in the list of organisations related to the item, these content ids must be present in the item organisation links hash.",
    type: "array",
    items: {
      "$ref": "#/definitions/guid",
    },
  },
  attachments_with_thumbnails: {
    description: "An ordered list of attachments",
    type: "array",
    items: {
      description: "Generated HTML for each attachment including thumbnail and download link",
      type: "string",
    },
  },
  first_public_at: {
    description: "DEPRECATED. The date the content was first published. Used in details. Deprecated in favour of top level `first_published_at`.",
    type: "string",
    format: "date-time",
  },
  brexit_no_deal_notice: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
      },
    },
    description: "A list of URLs and titles for a brexit no deal notice.",
  },
  ordered_featured_links: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
      },
    },
    description: "A set of featured links to display.",
  },
  ordered_featured_documents: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
        "image",
        "summary",
        "public_updated_at",
        "document_type",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
        image: {
          "$ref": "#/definitions/image",
        },
        summary: {
          type: "string",
        },
        public_updated_at: {
          type: [
            "string",
            "null",
          ],
        },
        document_type: {
          type: [
            "string",
            "null",
          ],
        },
      },
    },
    description: "A set of featured documents to display.",
  },
  promotional_feature_item_image: {
    items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "summary",
          "image",
        ],
        properties: {
          title: {
            "$ref": "#/definitions/promotional_feature_item_title",
          },
          href: {
            "$ref": "#/definitions/promotional_feature_item_href",
          },
          summary: {
            "$ref": "#/definitions/promotional_feature_item_summary",
          },
          image: {
            "$ref": "#/definitions/image",
          },
          double_width: {
            "$ref": "#/definitions/promotional_feature_item_double_width",
          },
          links: {
            "$ref": "#/definitions/promotional_feature_item_links",
          },
        },
      },
    },
  },
  promotional_feature_youtube: {
    items: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "summary",
          "youtube_video",
        ],
        properties: {
          title: {
            "$ref": "#/definitions/promotional_feature_item_title",
          },
          href: {
            "$ref": "#/definitions/promotional_feature_item_href",
          },
          summary: {
            "$ref": "#/definitions/promotional_feature_item_summary",
          },
          double_width: {
            "$ref": "#/definitions/promotional_feature_item_double_width",
          },
          links: {
            "$ref": "#/definitions/promotional_feature_item_links",
          },
          youtube_video: {
            type: "object",
            additionalProperties: false,
            required: [
              "id",
            ],
            properties: {
              id: {
                type: "string",
              },
              alt_text: {
                type: "string",
              },
            },
          },
        },
      },
    },
  },
  promotional_feature_item_title: {
    type: [
      "string",
      "null",
    ],
  },
  promotional_feature_item_href: {
    type: [
      "string",
      "null",
    ],
  },
  promotional_feature_item_summary: {
    type: "string",
  },
  promotional_feature_item_double_width: {
    type: "boolean",
  },
  promotional_feature_item_links: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "href",
      ],
      properties: {
        title: {
          type: "string",
        },
        href: {
          type: "string",
        },
      },
    },
  }
}
