# Working with JSON Schema keywords

There are various keywords available to use in your content schema. Some of the keywords listed below have been used in our more complex schemas.

| Keyword                                               |  Explanation                                                                                    |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`type`][data-types]                                  | The data type of a schema                                                                       |
| [`required`][required]                                | Specify object-level properties that must exist - by default all object properties are optional |
| [`enum`][enum]                                        | To specify values a request parameter or model property can accept                              |
| [`oneOf`][oneof], [`anyOf`][anyof], [`allOf`][allof]  | These allow you to validate the use of other subschemas in your schema                          |
| [`$ref`][ref]                                         | To include a subschema within your schema. It can be either a relative or absolute URI          |
| [`additionalProperties`][additional-properties]       | Controls whether properties that are not already specified can be accepted. By default any additional properties are allowed     |


[data-types]: https://swagger.io/docs/specification/data-models/data-types/
[required]: https://spacetelescope.github.io/understanding-json-schema/reference/object.html?highlight=required#required
[enum]: https://spacetelescope.github.io/understanding-json-schema/reference/object.html?highlight=required#required
[oneof]: https://spacetelescope.github.io/understanding-json-schema/reference/combining.html?highlight=oneof#oneof
[anyof]: https://spacetelescope.github.io/understanding-json-schema/reference/combining.html?highlight=anyof#anyof
[allof]: https://spacetelescope.github.io/understanding-json-schema/reference/combining.html?highlight=allof#allof
[ref]: https://spacetelescope.github.io/understanding-json-schema/structuring.html?highlight=$ref
[additional-properties]: https://spacetelescope.github.io/understanding-json-schema/reference/object.html?highlight=additionalproperties#properties
