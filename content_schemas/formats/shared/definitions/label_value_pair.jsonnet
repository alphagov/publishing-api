{
  label_value_pair: {
    description: "One of many possible values a user can select from",
    type: "object",
    additionalProperties: false,
    required: [
      "label",
      "value",
    ],
    properties: {
      label: {
        description: "A human readable label",
        type: "string",
      },
      value: {
        description: "A value to use for form controls",
        type: "string",
      },
      default: {
        description: "The default option for a radio facet",
        type: "boolean"
      }
    },
  },
}
