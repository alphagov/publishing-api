local FileAttachmentAssetProperties = {
  accessible: { type: "boolean", },
  alternative_format_contact_email: { type: "string", },
  attachment_type: { type: "string", enum: ["file"], },
  content_type: { type: "string", },
  file_size: { type: "integer", },
  filename: { type: "string", },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  number_of_pages: { type: "integer", },
  preview_url: { type: "string", format: "uri", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local HtmlAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["html"], },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local ExternalAttachmentAssetProperties = {
  attachment_type: { type: "string", enum: ["external"], },
  id: { type: "string" },
  locale: { "$ref": "#/definitions/locale", },
  title: { type: "string", },
  url: { type: "string", format: "uri", },
};

local PublicationAttachmentAssetProperties = {
  command_paper_number: { type: "string", },
  hoc_paper_number: { type: "string", },
  isbn: { type: "string", },
  parliamentary_session: { type: "string", },
  unique_reference: { type: "string", },
  unnumbered_command_paper: { type: "boolean", },
  unnumbered_hoc_paper: { type: "boolean", },
};

{
  image_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "content_type",
      "url",
    ],
    properties: {
      alt_text: { type: "string", },
      caption: { type: "string", },
      content_type: { type: "string", },
      credit: { type: "string", },
      url: { type: "string", format: "uri", },
    },
  },

  file_attachment_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "attachment_type",
      "content_type",
      "id",
      "url",
    ],
    properties: FileAttachmentAssetProperties,
  },

  specialist_publisher_attachment_asset: {
    type: "object",
    additionalProperties: false,
    required: [
      "attachment_type",
      "content_id",
      "content_type",
      "id",
      "url",
    ],
    properties: FileAttachmentAssetProperties + {
      content_id: { "$ref": "#/definitions/guid", },
      created_at: { format: "date-time", },
      updated_at: { format: "date-time", },
    },
  },

  publication_attachment_asset: {
    oneOf: [
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "content_type",
          "id",
          "url",
        ],
        properties: FileAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "id",
          "url",
        ],
        properties: HtmlAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      },
      {
        type: "object",
        additionalProperties: false,
        required: [
          "attachment_type",
          "id",
          "url",
        ],
        properties: ExternalAttachmentAssetProperties + PublicationAttachmentAssetProperties,
      }
    ],
  },
}
