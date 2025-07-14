module Presenters
  module Queries
    class ChangeHistory
      TABLES = {
        change_notes: ChangeNote.arel_table,
        editions: Edition.arel_table,
        documents: Document.arel_table,
      }.freeze

      def initialize(edition)
        @edition = edition
      end

      def call
        ChangeNote.where(
          ChangeNote.arel_table[:id].in(subquery),
        ).order(:public_timestamp)
      end

    private

      attr_reader :edition

      def subquery
        query = TABLES[:editions][:document_id]
          .eq(edition.document_id)
          .and(TABLES[:editions][:user_facing_version].lteq(edition.user_facing_version))
          .and(TABLES[:change_notes][:public_timestamp].not_eq(nil))

        link_queries.each do |q|
          query = query.or(q)
        end

        query ? arel_joins.where(query) : []
      end

      def link_queries
        links.map do |link|
          TABLES[:change_notes].grouping(
            TABLES[:documents][:content_id]
              .eq(link.target_content_id)
              .and(TABLES[:change_notes][:public_timestamp].gt(link.created_at)),
          )
        end
      end

      def links
        @links ||= Link
                     .select("target_content_id, min(created_at) as created_at")
                     .where(link_type: "embed", edition_id: edition.document.editions)
                     .group(:target_content_id)
      end

      def arel_joins
        TABLES[:change_notes]
          .project(TABLES[:change_notes][:id])
          .join(TABLES[:editions])
          .on(TABLES[:editions][:id].eq(TABLES[:change_notes][:edition_id]))
          .join(TABLES[:documents])
          .on(TABLES[:editions][:document_id].eq(TABLES[:documents][:id]))
      end
    end
  end
end
