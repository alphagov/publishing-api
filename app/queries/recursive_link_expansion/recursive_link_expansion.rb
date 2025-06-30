module Queries
  module RecursiveLinkExpansion
    class RecursiveLinkExpansion
      def initialize(edition)
        @edition = edition
        @links = ::Queries::RecursiveLinkExpansion::LinkExpansionRules.for(edition.schema_name)
      end

      def call
        base_case = BaseEdition.new(@edition, @links).call

        recursive_case = Edition.with(
          lookahead: Lookahead.new(@links).call,
          forward_link_set_links: ForwardLinkSetLinks.new.call,
          forward_edition_links: ForwardEditionLinks.new.call,
          reverse_link_set_links: ReverseLinkSetLinks.new.call,
          reverse_edition_links: ReverseEditionLinks.new.call,
          all_links: [
            Arel.sql("SELECT * from forward_link_set_links"),
            Arel.sql("SELECT * from forward_edition_links"),
            Arel.sql("SELECT * from reverse_link_set_links"),
            Arel.sql("SELECT * from reverse_edition_links"),
          ],
        ).from("all_links").select("all_links.*")

        Edition.with_recursive(
          linked_editions: [
            base_case,
            Arel.sql(recursive_case.to_sql), # Workaround to ensure the recursive case is wrapped in parens
          ],
        ).from("linked_editions").select("linked_editions.*")
      end
    end
  end
end
