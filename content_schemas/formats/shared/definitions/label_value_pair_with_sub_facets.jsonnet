{
  label_value_pair_with_sub_facets: {
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
      main_facet_label: {
        description: "A label that refers to the main facet label of this facet if it is a sub facet. The label is used to generate sub facet labels on frontend apps.",
        type: "string",
      },
      main_facet_value: {
        description: "A value that refers to the main facet value of this facet if it is a sub facet. The value is used to group sub facets into sub category groupings for navigational purposes.",
        type: "string",
      },
      sub_facets: {
        description: "Possible values to show for non-dynamic select nested facets. All values are shown regardless of the search.",
        type: "array",
        items: {
          "$ref": "#/definitions/label_value_pair",
        },
      },
      default: {
        description: "The default option for a radio facet",
        type: "boolean"
      }
    },
  },
}
