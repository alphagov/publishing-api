{
   embedded_object(properties, required = null):: {
      type: "object",
      patternProperties: {
        "^[a-z0-9]+(?:-[a-z0-9]+)*$": {
            type: "object",
            additionalProperties: false,
            properties: properties,
        } + (if required != null then { required: required } else {})
      }
   }
}
