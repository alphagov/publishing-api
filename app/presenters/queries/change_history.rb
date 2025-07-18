module Presenters
  module Queries
    class ChangeHistory
      def initialize(edition)
        @edition = edition
      end

      def call
        unioned = Arel::Nodes::UnionAll.new(
          change_notes_for_edition.arel,
          change_notes_for_linked_content_blocks.arel,
        )

        # Wrap the unioned subquery so ActiveRecord can use it
        ChangeNote
          .from(Arel::Nodes::TableAlias.new(unioned, ChangeNote.table_name))
          .order(:public_timestamp)
      end

    private

      attr_reader :edition

      def change_notes_for_edition
        ChangeNote
          .joins(:edition)
          .where(editions: { document: edition.document })
          .where("user_facing_version <= ?", edition.user_facing_version)
          .where.not(public_timestamp: nil)
      end

      def change_notes_for_linked_content_blocks
        return ChangeNote.none if embed_links.empty?

        conditions = embed_links.map do |(target_content_id, created_at)|
          ChangeNote.joins(edition: :document)
                    .where(documents: { content_id: target_content_id })
                    .where("public_timestamp > ?", created_at)
        end

        conditions.reduce { |acc, q| acc.or(q) }
      end

      def embed_links
        @embed_links ||= Link
                          .where(link_type: "embed", edition_id: edition.document.editions.select(:id))
                          .group(:target_content_id)
                          .minimum(:created_at)
      end
    end
  end
end
