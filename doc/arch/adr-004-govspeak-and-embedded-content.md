## Decision Record: Govspeak and embedded content

GOV.UK uses its Markdown dialect, govspeak, as the source of content for the
site. At present the conversion from govspeak to HTML is done in each publishing
app. This is a duplication of responsibility, and means that we have subtly
different versions of govspeak in every app.

To improve this, govspeak rendering will be moved to be a responsibility of the
publishing API, and embedded content will be separated out so that the details
are sent to frontends rather than the rendered output.


## Description

### Govspeak rendering

Conversion of govspeak into HTML becomes the responsibility of the publishing
platform. Publishing apps will send raw govspeak, and content-store will
continue to receive HTML; the conversion from one to the other will be done in
between those points.

This solution was chosen because it fits with the principles of the publishing
platform, namely:

 * the platform is responsible for transforming publisher content into frontend
   content;
 * frontends should do as little as possible at render time, to reduce latency;
 * responsibility for shared actions lives within the platform as far as
   possible.

It is yet to be decided if the conversion is done directly in publishing-api,
or in a new dedicated govspeak service that sits between publishing-api and
content-store. The latter increases flexibility and makes it possible for other
apps to call out to it for govspeak rendering; however it would be more complex
and increase the number of apps involved in the publishing chain.


## Embedded content

One of the features of govspeak is that it can embed other items, eg contacts,
in the markdown, and they are expanded in the rendered HTML. This embedded
content will be resolved by publishing-api and rendered along with the
rest of the document. The flow is as follows.

A Whitehall editor edits the body of a document and chooses a contact from a
javascript widget populated by the linkables endpoint of publishing-api. This
causes text containing a contact ID to be inserted into the document body:

```markdown
Some text

[Contact:1234]

More text
```

The short ID continues to be used here as it is more friendly for editors,
some of whom know their frequently-used IDs.

When sending to publishing-api, Whitehall converts this to an `embed` element
with the relevant document_type and content_id:

```markdown
Some text

[embed:contact:2b4d92f3-f8cd-4284-aaaa-25b3a640d26c]

More text
```

and additionally adds that content_id to the the relevant element of the
`links` hash:

```json
"links": {
  "contacts": [
    "2b4d92f3-f8cd-4284-aaaa-25b3a640d26c"
  ]
}
```

Publishing API's existing link expansion functionality will resolve the content
ID to a JSON object (fields to be determined, this is an example only):

```json
"expanded_links": {
  "contacts": [
    {
      "content_id": "2b4d92f3-f8cd-4284-aaaa-25b3a640d26c" ,
      "name": "Contact name",
      "street_address": "1 Main Street, Anytown",
      "postal_code": "AT1 1TA",
      "email": "name@organisation.gov.uk"
    }
  ]
}
```

The govspeak renderer will then convert this to HTML, replacing the embedded
content with the data from the relevant entry in the expanded links.

## Consequences

As a consequence of rendering govspeak within the publishing platform, rather
than in the frontends, we forego the ability to easily change the HTML output
of the embedded items. If this is changed for a type of embedded content, all
documents that use that type will need to be re-rendered and re-sent to the
content store.

Since there probably will be work that iterates on this HTML in the future,
some work to speed up bulk publishing will be required.

