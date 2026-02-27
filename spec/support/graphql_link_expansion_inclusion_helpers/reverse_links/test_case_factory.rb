module GraphqlLinkExpansionInclusionHelpers
  module ReverseLinks
    class TestCaseFactory
      class << self
        def all
          with_drafts_values = [true, false]
          root_locale_values = [Edition::DEFAULT_LOCALE, "fr"]

          state_values = %w[published unpublished draft]
          withdrawal_values = [true, false, nil]
          permitted_unpublished_link_type_values = [true, false, nil]

          renderable_document_type_values = [false, true]
          locale_values = [Edition::DEFAULT_LOCALE, "fr", "hu"]
          allowed_reverse_link_type_values = [true, false]
          link_kind_values = %w[link_set_links edition_links]

          with_drafts_values.product(
            root_locale_values,
            state_values,
            withdrawal_values,
            permitted_unpublished_link_type_values,
            renderable_document_type_values,
            locale_values,
            allowed_reverse_link_type_values,
            link_kind_values,
          ).map {
            {
              with_drafts: _1,
              root_locale: _2,
              state: _3,
              withdrawal: _4,
              permitted_unpublished_link_type: _5,
              renderable_document_type: _6,
              locale: _7,
              allowed_reverse_link_type: _8,
              link_kind: _9,
            }
          }
            .reject { |test_case|
              [
                redundant_locale(test_case),
                invalid_state(test_case),
              ].any?
            }
              .map { TestCase.new(**it) }
        end

      private

        def redundant_locale(test_case)
          test_case[:root_locale] == Edition::DEFAULT_LOCALE &&
            test_case[:locale] == "hu"
        end

        def invalid_state(test_case)
          if test_case[:state] == "unpublished"
            test_case[:withdrawal].nil? || test_case[:permitted_unpublished_link_type].nil?
          else
            !test_case[:withdrawal].nil? || !test_case[:permitted_unpublished_link_type].nil?
          end
        end
      end
    end
  end
end
