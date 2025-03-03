{
   embedded_object(properties, required):: {
      type: "object",
      patternProperties: {
        "^[a-z0-9]+(?:-[a-z0-9]+)*$": {
            type: "object",
            required: ["title"] + required,
            additionalProperties: false,
            properties: {
              title: {
                type: "string"
              }
            } + properties,
            order: ["title"] + std.objectFields(properties),
        }
      }
   }
}
