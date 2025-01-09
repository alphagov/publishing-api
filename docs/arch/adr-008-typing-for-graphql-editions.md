# Decision Record: Typing for GraphQL proof of concept

## Context

Up to now, a single type has been implemented in the GraphQL proof of concept for each content type we are supporting. A type may support one or more document types, as happens with the content schemas.

However, it has been decided that a single edition type should be used going forwards. Additional types can be added for editions where specific optimisations are needed, or where we would like to allow queries to be made outside of the edition model.

## Reason

Publishing API models all documents as editions. Other than validation against content schemas at the point of receiving the PUT content request, it is agnostic to the content within the edition. In theory, all editions can support any fields and any links.

By implementing a GraphQL type for each document type, we were hardcoding the fields that could be supported. This included limiting the fields that could be requested within links.

This would lead to additional development work in Publishing API's GraphQL codebase should a new document type, field or link be added to the schemas.

Additionally, development work would be required in Publishing API's GraphQL codebase should a frontend application wish to retrieve additional fields from within a linked document, as we would have hardcoded a list of fields which could be retrieved.

In some cases, we will need to create specific types for some documents if we see a benefit (e.g. creating a bespoke query that doesn’t map to any edition or creating a more performant query for a specific reason). Changing to a single edition type does not prevent this.

## Consequences

We have removed the hardcoding and duplication amongst the varieties of edition we have currently implemented. These changes will make it easier to implement new document types, as the fields and links have already been defined.

The Ministers Index Type is being retained, since that contains custom optimisations specific to the links on that page. In future, it may be possible to decouple that type from editions entirely, meaning we wouldn't need to ever publish that page from Whitehall.

Since all links are now returned as an edition, any field can be selected from them, not just those that have been defined in the link type. This makes queries much more flexible, as the frontend application can request any fields it likes from the links, without any changes being made in Publishing API to support that field. If a frontend application queries for a field or link that does not exist on a given edition, it will receive an empty value for that field.

We gain this flexibility at the expense of losing feedback on which fields could be present for an edition of a given document/content type. With stronger typing, we receive errors guiding us on which fields are accepted for specific document/content types, but it involves writing a lot of bespoke types on the Publishing API side. However, given the close links between teams working on the frontend and publishing applications, and the presence of defined content schemas, there should never be a need for a frontend application to request fields/links which do not exist.

The single edition approach provides a similar level of feedback as retrieving data from the Content Store. Content Store data would never contain fields that would always be null for a given type, but it might also exclude optional/nullable fields.

We also discussed the idea of a more compositional approach to types, whereby we define shared link types and field definitions once and then include them in specific types, but this would still have required more upfront work and might have resulted in some complex architecture.

Ultimately we opted for the approach that would allow us to test GraphQL across all document/content types quickly, with the most flexibility and least changes in the frontend applications.
