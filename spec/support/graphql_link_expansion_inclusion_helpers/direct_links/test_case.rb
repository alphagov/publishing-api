module GraphqlLinkExpansionInclusionHelpers
  module DirectLinks
    class TestCase
      def initialize(
        with_drafts:,
        root_locale:,
        state:,
        renderable_document_type:,
        locale:,
        withdrawal:,
        permitted_unpublished_link_type:
      )
        @with_drafts = with_drafts
        @root_locale = root_locale
        @state = state
        @renderable_document_type = renderable_document_type
        @locale = locale
        @withdrawal = withdrawal
        @permitted_unpublished_link_type = permitted_unpublished_link_type
      end

      attr_reader :with_drafts, :root_locale, :state, :renderable_document_type, :locale

      def description
        inclusion_string = included ? "includes" : "excludes"
        state_string = if state == "unpublished"
                         link_type_description = permitted_unpublished_link_type ? "permitted" : "unpermitted"
                         unpublishing_type_description = withdrawal ? "withdrawal" : "non-withdrawal"
                         "an unpublished #{unpublishing_type_description} with a #{link_type_description} link type"
                       else
                         state
                       end
        locale_string = locale == "default" ? "in the default locale" : "in the locale \"#{locale}\""
        document_type_string = "a #{renderable_document_type ? 'renderable' : 'non-renderable'} document type"

        "#{inclusion_string} a target edition that is #{[state_string, document_type_string, locale_string].to_sentence}"
      end

      def with_drafts_description
        "when #{with_drafts ? 'accepting' : 'rejecting'} drafts"
      end

      def source_edition_locale_description
        "when the source edition's locale is \"#{root_locale}\""
      end

      def linked_edition_document_type
        @linked_edition_document_type ||= if renderable_document_type
                                            renderable_types = GovukSchemas::DocumentTypes.valid_document_types - Edition::NON_RENDERABLE_FORMATS
                                            renderable_types.sample
                                          else
                                            Edition::NON_RENDERABLE_FORMATS.sample
                                          end
      end

      def link_type
        @link_type ||= begin
          return "ordered_related_items" unless permitted_unpublished_link_type

          Link::PERMITTED_UNPUBLISHED_LINK_TYPES.sample
        end
      end

      def linked_edition_unpublishing_type
        @linked_edition_unpublishing_type ||= begin
          return "withdrawal" if withdrawal

          Unpublishing::VALID_TYPES.reject { it == "withdrawal" }.sample
        end
      end

      def included
        renderable_document_type &&
          (with_drafts || state != "draft") &&
          (state != "unpublished" ||
           (withdrawal && permitted_unpublished_link_type)
          ) &&
          [Edition::DEFAULT_LOCALE, root_locale].include?(locale)
      end

    private

      attr_reader :withdrawal, :permitted_unpublished_link_type
    end
  end
end
