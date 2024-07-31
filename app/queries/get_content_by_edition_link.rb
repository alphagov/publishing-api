# TODO: Queries::GetLinked is similar but gets links that belong to a link set
# like an organisation.
# It expects one type of link_type, for our purposes we want to have any embedded link_type
module Queries
  module GetContentByEditionLink
    def self.call(target_content_id)
      editions = Edition.live
                        .joins(:links)
                        .where(links: { target_content_id: target_content_id }) # Can we have a link_type of "embedded"?
                        .select("editions.id, editions.title, editions.base_path, editions.document_type")

      # TODO: I tried using Presenters::Queries::ExpandedLinkSet to return each edition and expand all of its links
      # This works although it returns much more than we need, until it tries to expand one of our embedded links.
      # This may be an issue with the spike.
      Presenters::Queries::LinkedContentItemsPresenter.new(editions).present
    end
  end
end
