(import "base_edition_links.jsonnet") + {
  government: {
    description: "The government associated with this document",
    maxItems: 1,
  },
  organisations: "",
  parent: "",
  primary_publishing_organisation: {
    description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
    maxItems: 1,
  },
  related_policies: "",
  topical_events: "",
}
