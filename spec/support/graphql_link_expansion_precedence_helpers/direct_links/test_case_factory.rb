module GraphqlLinkExpansionPrecedenceHelpers
  module DirectLinks
    class TestCaseFactory
      class << self
        def all(target_content_ids_differ:)
          query_values = [
            { with_drafts: true, root_locale: Edition::DEFAULT_LOCALE },
            { with_drafts: true, root_locale: "fr" },
            { with_drafts: false, root_locale: Edition::DEFAULT_LOCALE },
            { with_drafts: false, root_locale: "fr" },
          ]

          link_kind_values = %w[link_set edition]

          # state, withdawal, permitted unpublished link type
          state_values = [
            ["published", nil, nil],
            ["unpublished", true, true],
            ["unpublished", true, false],
            ["unpublished", false, true],
            ["unpublished", false, false],
          ]

          renderable_document_type_values = [false, true]
          locale_values = [Edition::DEFAULT_LOCALE, "fr", "hu"]

          edition_values = link_kind_values.product(
            state_values,
            renderable_document_type_values,
            locale_values,
          ).map do
            {
              link_kind: _1,
              state: _2[0],
              withdrawal: _2[1],
              permitted_unpublished_link_type: _2[2],
              renderable_document_type: _3,
              locale: _4,
            }
          end

          edition_pairs = edition_values.combination(2).to_a

          query_values
            .product(edition_pairs)
            .map { { **_1, linked_editions: _2 } }
            .reject { |test_case|
              [
                redundant_locale(test_case),
                mismatching_link_type(test_case),
                *unless target_content_ids_differ
                   [
                     document_with_two_editions_in_live_content_store(test_case),
                     duplicate_edition_and_link_kind(test_case),
                     single_edition_with_varying_properties(test_case),
                   ]
                 end,
              ].any?
            }
            .map { TestCase.new(**it, target_content_ids_differ:) }
        end

      private

        def fields_equal(a, b, *fields) # rubocop:disable Naming/MethodParameterName
          fields.all? { a[it] == b[it] }
        end

        # we only need to test one non-default/fallback non-root-matching locale
        def redundant_locale(test_case)
          test_case[:root_locale] == Edition::DEFAULT_LOCALE &&
            test_case[:linked_editions].any? { it[:locale] == "hu" }
        end

        # the link type must be the same for two targets to compete, so we
        # filter out cases where we have both true and false for the permitted
        # unpublished link type (from which we derive the link type)
        def mismatching_link_type(test_case)
          test_case[:linked_editions]
            .map { it[:permitted_unpublished_link_type] }
            .compact.uniq.size > 1
        end

        # given the target content ID is the same, the document must be the same
        # if the locale is the same. in such cases, we can't have two editions
        # in the same content store
        def document_with_two_editions_in_live_content_store(test_case)
          fields_equal(*test_case[:linked_editions], :locale) &&
            test_case[:linked_editions]
              .map { it[:state] }
              .sort == %w[published unpublished]
        end

        # given the target content ID is the same, the edition must be the same
        # if the state and locale are the same. in such cases, we only want one
        # edition and one link of any link kind
        def duplicate_edition_and_link_kind(test_case)
          fields_equal(*test_case[:linked_editions], :link_kind, :state, :locale)
        end

        # given the target content ID is the same, the edition must be the same
        # if the state and locale are the same. in such cases, the properties of
        # the edition or its unpublishing can't vary
        def single_edition_with_varying_properties(test_case)
          fields_equal(*test_case[:linked_editions], :state, :locale) &&
            [
              !fields_equal(*test_case[:linked_editions], :renderable_document_type),
              test_case[:linked_editions]
                .map { it[:withdrawal].to_s }
                .sort == %w[false true],
            ].any?
        end
      end
    end
  end
end
