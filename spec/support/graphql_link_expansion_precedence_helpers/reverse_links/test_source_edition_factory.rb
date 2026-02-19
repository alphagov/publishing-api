module GraphqlLinkExpansionPrecedenceHelpers
  module ReverseLinks
    class TestSourceEditionFactory
      include FactoryBot::Syntax::Methods

      def initialize(
        state:,
        renderable_document_type:,
        locale:,
        withdrawal:,
        link_kind:,
        content_id:
      )
        @state = state
        @renderable_document_type = renderable_document_type
        @locale = locale
        @withdrawal = withdrawal
        @link_kind = link_kind
        @content_id = content_id
      end

      def call
        Edition.find_by(state:, document:) ||
          create(
            :live_edition,
            title: "edition #{Edition.count} (#{link_kind})",
            state:,
            document_type:,
            document:,
          ).tap do
            if state == "unpublished"
              create(:unpublishing, edition: it, type: unpublishing_type)
            end
          end
      end

    private

      attr_reader :state, :renderable_document_type, :locale, :withdrawal, :link_kind, :content_id

      def document_type
        if renderable_document_type
          (
            GovukSchemas::DocumentTypes.valid_document_types -
            Edition::NON_RENDERABLE_FORMATS
          ).sample
        else
          Edition::NON_RENDERABLE_FORMATS.sample
        end
      end

      def document
        Document.find_by(content_id:, locale:) ||
          create(:document, content_id:, locale:)
      end

      def unpublishing_type
        return "withdrawal" if withdrawal

        Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
      end
    end
  end
end
