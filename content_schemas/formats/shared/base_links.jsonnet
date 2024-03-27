{
  taxons: "Prototype-stage taxonomy label for this content item",
  ordered_related_items: "Related items, can be any page on GOV.UK. Mostly used for mainstream content to power the sidebar. Ordering of the links is determined by the editor in Content Tagger.",
  ordered_related_items_overrides: "Related items, can be any page on GOV.UK. Overrides 'more like this' automatically generated links in the beta navigation.",
  mainstream_browse_pages: "Powers the /browse section of the site. These are known as sections in some legacy apps.",
  meets_user_needs: "The user needs this piece of content meets.",
  organisations: "All organisations linked to this content item. This should include lead organisations.",
  parent: {
    description: "The parent content item.",
    maxItems: 1,
  },
  policy_areas: "A largely deprecated tag currently only used to power email alerts.",
  primary_publishing_organisation: {
    description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
    maxItems: 1,
  },
  original_primary_publishing_organisation: "The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.",
  lead_organisations: "DEPRECATED: A subset of organisations that should be emphasised in relation to this content item. All organisations specified here should also be part of the organisations array.",
  suggested_ordered_related_items: "Used for displaying related content on most pages, except for step-by-step and fatality notices. Links and their ordering are determined by the machine learning algorithms.",
  finder: "Powers links from content back to finders the content is surfaced on",
}
