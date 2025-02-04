{
   embedded_object(properties, required):: {
      type: "object",
      patternProperties: {
        "^[a-z0-9]+(?:-[a-z0-9]+)*$": {
            type: "object",
            required: ["name"] + required,
            additionalProperties: false,
            properties: {
              name: {
                type: "string"
              }
            } + properties,
            order: ["name"] + std.objectFields(properties),
        }
      }
   }
}
