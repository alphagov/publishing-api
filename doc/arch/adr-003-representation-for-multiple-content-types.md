## Decision Record: Representation for Multiple Content Types

We have a requirement to represent multiple content types for some fields when
sending content items back and forth between Publishing Applications and the
Publishing API. This document captures the options that were considered and the
reasons for why Option 1 was chosen.

This decision is referenced in [RFC 35: Explicitly make the details hash non-opaque](https://gov-uk.atlassian.net/wiki/display/GOVUK/RFC+35%3A+Explicitly+make+the+details+hash+non-opaque?focusedCommentId=42827845#comment-42827845).

## Option 1

This option is the most verbose and nests an array of JSON objects. These
objects have properties `content_type` and `content`.

```json
{
  "details": {
    "body": [
      { "content_type": "text/html", "content": "<h1>content</h1>" },
      { "content_type": "text/govspeak", "content": "# content" }
    ]
  }
}
```

## Option 2

This option is the least verbose and nests a JSON object that has properties for
each of the content types.

```json
{
  "details": {
    "body": {
      "text/html": "<h1>content</h1>",
      "text/govspeak": "# content"
    }
  }
}
```

## Option 3

This is an alternative that doubly nests JSON objects. The inner object has
properties for each of the content types.

```json
{
  "details": {
    "body": {
      "multiple_representations": {
        "text/html": "<h1>content</h1>",
        "text/govspeak": "# content"
      }
    }
  }
}
```

## Decision

The decision was made to choose Option 1. This representation is not very
compact, but it means that JSON objects could store additional information if
required, such as a Govspeak version. It was noted that this option may not
be the easiest for Publishing Applications to work with.

Option 2 was rejected on the basis that it doesn't clearly demonstrate which
fields genuinely contain multiple representations, compared with those that
could contain other properties. The Publishing API is responsible for only
forwarding the text/html content type and ambiguity in the representation means
that it would have to make a lot of assumptions about which fields contain
multiple representations.

Option 3 was rejected on the basis that it's more-or-less equivalent to Option 1,
but it lacks the ability to include additional properties in the future if
required. Also, it isn't significantly easier for Publishing Applications to
work with to justify choosing this option over Option 1.

## Status

Accepted on 20/11/2015.
