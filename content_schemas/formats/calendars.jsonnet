(import "shared/default_format.jsonnet") + {
    document_type: ["bank_holidays", "clocks_change"],
     content_id: "string",
     definitions: {
         details: {
               type: "object",
               additionalProperties: false,
               required: ["divisions"],
               properties: {
                     divisions: {
                         nation_slug: "string" {
                             title: "string",
                             year: {
                                   title: "string",
                                   date: {
                                     type: 'string',
                                     format: 'date-time'
                                   },
                                   notes: "string",
                                   bunting: {
                                     style: "string",
                                     visible: "boolean"
                                   }
                             }
                         }
                     }
               }
         }
    }
 }