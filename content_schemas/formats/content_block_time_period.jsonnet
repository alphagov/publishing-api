local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_time_period",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        note: {
          type: "string"
        },
        description: {
          type: "string"
        },
        date_time: {
          type: "object",
          additionalProperties: false,
          required: ["start", "end"],
          properties: {
            start: {
              type: "object",
              additionalProperties: false,
              properties: {
                date: {
                  type: "object",
                  additionalProperties: false,
                  required: ["year", "month", "day"],
                  properties: {
                    year: {
                      type: "string",
                    },
                    month: {
                      type: "string",
                    },
                    day: {
                      type: "string",
                    },
                  }
                },
                time: {
                  type: "object",
                  additionalProperties: false,
                  required: ["hour", "minute"],
                  properties: {
                    hour: {
                      type: "string",
                    },
                    minute: {
                      type: "string",
                    },
                  }
                }
              }
            },
            end: {
              type: "object",
              additionalProperties: false,
              properties: {
                date: {
                  type: "object",
                  additionalProperties: false,
                  required: ["year", "month", "day"],
                  properties: {
                    year: {
                      type: "string",
                    },
                    month: {
                      type: "string",
                    },
                    day: {
                      type: "string",
                    },
                  }
                },
                time: {
                  type: "object",
                  additionalProperties: false,
                  required: ["hour", "minute"],
                  properties: {
                    hour: {
                      type: "string",
                    },
                    minute: {
                      type: "string",
                    },
                  }
                }
              }
            },
          },
        },
      },
    },
  },
}

