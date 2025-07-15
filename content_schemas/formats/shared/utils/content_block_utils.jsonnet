{
   embedded_object(properties, required):: {
      type: "object",
      patternProperties: {
        "^[a-z0-9]+(?:-[a-z0-9]+)*$": {
            type: "object",
            required: required,
            additionalProperties: false,
            properties: {
              title: {
                type: "string"
              }
            } + properties,
        }
      }
   }
}
