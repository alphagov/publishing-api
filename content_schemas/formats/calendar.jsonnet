(import "shared/default_format.jsonnet") + {
    document_type: ["bank_holidays", "clocks_change"],
    content_id: "string",
    definitions: {
        event: {
            type: "object",
            additionalProperties: false,
            required: ["title", "date"],
            properties: {
                title: {
                    type: "string",
                    description: "The title of the event e.g.: Christmas Day"
                },
                date: {
                    type: "string",
                    format: "date-time",
                    description: "The date of the event, e.g.: 2015-12-25T00:00:00Z"
                },
                notes: {
                    type: "string",
                    description: "Notes about the event e.g. substitute_day or extra_bank_holiday"

                },
                bunting: {
                    type: "object",
                    additionalProperties: false,
                    required: ["visible"],
                    properties: {
                        style: {
                            type: "string",
                            description: "The style of bunting to display"
                        },
                        visible: {
                            type: "boolean",
                            description: "Indicates whether the bunting should be displayed"
                        }
                    }
                }
            }
        },
        year: {
            type: "object",
            additionalProperties: false,
            required: ["yearNumber", "events"],
            properties: {
                yearNumber: {
                    type: "number",
                    description: "The year as a number e.g.: 2015"
                },
                events: {
                    type: "array",
                    additionalProperties: false,
                    items: {
                        "$ref": "#/definitions/event"
                    }
                }
            }
        },
        details: {
            type: "object",
            additionalProperties: false,
            required: ["divisions"],
            properties: {
                divisions: {
                    type: "array",
                    additionalProperties: false,
                    items: {
                        type: "object",
                        additionalProperties: false,
                        required: ["divisionName", "years"],
                        properties: {
                            divisionName: {
                                type: "string",
                                description: "The name of the division e.g. England and Wales"
                            },
                            years: {
                                type: "array",
                                additionalProperties: false,
                                items: {
                                    "$ref": "#/definitions/year"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}