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
  original_primary_publishing_organisation: "The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.",
  related_policies: "",
  topical_events: "",
}
