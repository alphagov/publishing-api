module Commands
  module V2
    # This import command is included as a temporary addition to the Publishing
    # API to support Maslow migration.
    # It should no longer be needed by March 2017 and may be removed at this
    # point.
    #
    # We are planning to have an import endpoint, at the time of writing it is
    # not clear whether it will follow the API used here.
    class Import < BaseCommand
      def call
        unless UuidValidator.valid?(payload[:content_id])
          raise_command_error(
            422,
            "Provided content_id not a valid UUID",
            fields: {},
          )
        end

        content_id, locale = payload.values_at(:content_id, :locale)

        if locale.nil?
          raise CommandError.new(
            code: 422,
            message: "A locale must be specified",
          )
        end

        previous_document =
          Document.find_by(content_id: content_id, locale: locale)

        if previous_document
          previous_content_store_base_paths = get_base_path_content_store_pairs(
            previous_document,
          )

          delete_all(previous_document)
        else
          previous_content_store_base_paths = []
        end

        document = create_document(content_id, locale)
        payload[:history].map.with_index do |event, index|
          create_edition(document, event, index)
        end

        new_content_store_base_paths = get_base_path_content_store_pairs(document)

        after_transaction_commit do
          ImportWorker.perform_async(
            content_id: payload[:content_id],
            draft_base_paths_to_discard: draft_content_store_base_paths_to_discard(
              previous_content_store_base_paths,
              new_content_store_base_paths,
            ),
            live_base_path_to_delete: live_content_store_base_path_to_delete(
              previous_content_store_base_paths,
              new_content_store_base_paths,
            ),
          )
        end

        Success.new(content_id: payload[:content_id])
      end

    private

      def create_document(content_id, locale)
        Document.create(
          content_id: content_id,
          locale: locale,
        )
      end

      def create_edition(document, history_entry, index)
        validate_history_entry(document.locale, history_entry, index)

        content_item = document.editions.create!(
          history_entry.except(:states).merge(
            user_facing_version: index + 1,
            state: "draft",
          ),
        )

        update_content_item_state_information(content_item, history_entry[:states])

        # Force reload the association to ensure that the
        # draft_cannot_be_behind_live validator in the Edition model
        # gets the correct value
        document.reload.draft
      end

      def update_content_item_state_information(content_item, states)
        states.each do |state|
          case state[:name]
          when "unpublished"
            content_item.unpublish(
              state.slice(
                :type, :explanation, :alternative_path, :unpublished_at
              ),
            )
          when "superseded"
            content_item.supersede
          when "published"
            content_item.publish
          when "draft"
            content_item.update_attributes!(
              state: "draft",
              content_store: "draft",
            )
          else
            raise CommandError.new(
              code: 422,
              message: "Unrecognised state: #{state[:name]}.",
            )
          end
        end
      end

      def validate_history_entry(locale, history_entry, index)
        unrecognised_attributes = history_entry.keys - attributes

        unless unrecognised_attributes.empty?
          raise CommandError.new(
            code: 422,
            message: "Unrecognised attributes in payload: #{unrecognised_attributes}",
          )
        end

        schema_validator = SchemaValidator.new(
          payload: history_entry.except(:states).merge(locale: locale),
        )

        unless schema_validator.valid?
          raise CommandError.new(
            code: 422,
            message: "Schema validation failed: #{schema_validator.errors}",
            error_details: schema_validator.errors,
          )
        end

        unless history_entry.key?(:states)
          raise_command_error(
            422,
            "Missing states from history entry #{index}",
          )
        end

        history_entry[:states].each do |state|
          if state[:name] == "unpublished"
            unless state.key?(:type)
              raise_command_error(
                422,
                "Error processing history entry #{index}. "\
                "For a state of unpublished, a type must be provided",
                {}
              )
            end
          end

          unless state.key?(:name)
            raise_command_error(
              422,
              "Missing name for history entry state for history entry #{index}",
              {}
            )
          end

          supported_states = %w(draft published unpublished superseded)

          unless supported_states.include?(state[:name])
            raise CommandError.new(
              code: 422,
              message: "Unsupported state used at index #{index}: \
                        #{history_entry[:state]}, \
                        only #{supported_states} are supported",
            )
          end
        end
      end

      def get_base_path_content_store_pairs(document)
        document.editions.where(
          state: %w(draft published unpublished),
        ).group(:base_path).pluck(:base_path, Arel.sql("ARRAY_AGG(content_store)"))
      end

      def draft_content_store_base_paths_to_discard(
        previous_content_store_base_path_pairs,
        new_content_store_base_path_pairs
      )
        previous_content_store_base_paths =
          previous_content_store_base_path_pairs.map(&:first)
        new_content_store_base_paths =
          new_content_store_base_path_pairs.map(&:first)

        # As the draft content store should also contain whatever
        # content is in the live content store if no draft exists,
        # to find base_paths that need deleting from the draft
        # store, its necessary to check all the base paths.
        previous_content_store_base_paths - new_content_store_base_paths
      end

      def live_content_store_base_path_to_delete(
        previous_content_store_base_path_pairs,
        new_content_store_base_path_pairs
      )
        previous_live_base_path =
          live_base_path_from_base_path_content_store_pairs(
            previous_content_store_base_path_pairs,
          )

        new_live_base_path =
          live_base_path_from_base_path_content_store_pairs(
            new_content_store_base_path_pairs,
          )

        if !previous_live_base_path.nil? &&
            previous_live_base_path != new_live_base_path

          previous_live_base_path
        end
      end

      def live_base_path_from_base_path_content_store_pairs(pairs)
        live_paths = pairs.select { |x| x[1].include?("live") }
                       .map(&:first)

        case live_paths.length
        when 0
          nil
        when 1
          live_paths.first
        else
          raise "Multiple non-draft content items for base path"
        end
      end

      def attributes
        @attributes ||=
          %i[base_path states] + Edition.new.attributes.keys.map(&:to_sym) - %i[state locale]
      end

      def delete_all(document)
        document.editions.destroy_all
        document.destroy
      end
    end
  end
end
