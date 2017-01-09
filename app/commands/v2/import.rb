module Commands
  module V2
    class Import < BaseCommand
      def call
        unless UuidValidator.valid?(payload[:content_id])
          raise CommandError.new(
            code: 422,
            error_details: {
              error: {
                code: 422,
                message: "Content id not valid",
                fields: "content_id",
              }
            }
          )
        end

        previous_content_store_base_paths = get_base_path_content_store_pairs

        delete_all(payload[:content_id])
        payload[:history].map.with_index do |event, index|
          create_content_item(event, index, payload[:content_id])
        end

        new_content_store_base_paths = get_base_path_content_store_pairs

        after_transaction_commit do
          Commands::V2::RepresentDownstream.new.call(
            payload[:content_id],
            true
          )

          delete_content_from_live_content_store(
            previous_content_store_base_paths,
            new_content_store_base_paths
          )

          delete_content_from_draft_content_store(
            previous_content_store_base_paths,
            new_content_store_base_paths
          )
        end

        Success.new(content_id: payload[:content_id])
      end

    private

      def create_content_item(history_entry, index, content_id)
        validate_history_entry(history_entry, index)

        state_name = state_name_from_history_entry_state(history_entry[:state])

        content_item = Services::CreateContentItem.new(
          payload: history_entry.merge(
            content_id: content_id,
            user_facing_version: index + 1,
            state: state_name
          ),
          lock_version: index + 1,
        ).create_content_item

        update_content_item_state_information(content_item, history_entry[:state])
      end

      def state_name_from_history_entry_state(state)
        state.instance_of?(String) ? state : state[:name]
      end

      def update_content_item_state_information(content_item, state_info)
        case state_name_from_history_entry_state(state_info)
        when "unpublished"
          content_item.unpublish(
            state_info.slice(
              *%i(type explanation alternative_path unpublished_at)
            )
          )
        when "superseded"
          content_item.supersede
        when "published"
          content_item.publish
        end
      end

      def validate_history_entry(history_entry, index)
        unrecognised_attributes = history_entry.keys - attributes

        unless unrecognised_attributes.empty?
          raise CommandError.new(
            code: 422,
            message: "Unrecognised attributes in payload: #{unrecognised_attributes}"
          )
        end

        schema_validator = SchemaValidator.new(payload: history_entry.except(:state))

        unless schema_validator.valid?
          raise CommandError.new(
            code: 422,
            message: "Schema validation failed: #{schema_validator.errors}",
            error_details: schema_validator.errors
          )
        end

        unless history_entry.key?(:state)
          raise_command_error(
            422,
            "Missing state from history entry #{index}",
          )
        end

        state = history_entry[:state]

        if state.instance_of? String
          if state == "unpublished"
            raise_command_error(
              422,
              "Error processing history entry #{index}. "\
              "For a state of unpublished, a type must be provided",
              {}
            )
          end

          state_name = state
        elsif state.instance_of? Hash
          unless state.key?(:name)
            raise_command_error(
              422,
              "Missing name for history entry state for history entry #{index}",
              {}
            )
          end

          state_name = state[:name]
        else
          raise_command_error(
            422,
            "state for history entry #{index} is not a string or object",
            {}
          )
        end

        supported_states = %w(draft published unpublished superseded)

        unless supported_states.include?(state_name)
          raise CommandError.new(
            code: 422,
            message: "Unsupported state used at index #{index}: \
                      #{history_entry[:state]}, \
                      only #{supported_states} are supported"
          )
        end
      end

      def get_base_path_content_store_pairs
        ContentItem.where(
          content_id: payload[:content_id],
          state: %w(draft published unpublished)
        ).group(:base_path).pluck(:base_path, "ARRAY_AGG(content_store)")
      end

      def delete_content_from_draft_content_store(
        previous_content_store_base_paths,
        new_content_store_base_paths
      )
        # As the draft content store should also contain whatever
        # content is in the live content store if no draft exists,
        # to find base_paths that need deleting from the draft
        # store, its necessary to check all the base paths.
        draft_base_paths_to_delete =
          previous_content_store_base_paths.map { |x| x[0] } - \
          new_content_store_base_paths.map { |x| x[0] }

        draft_base_paths_to_delete.each do |base_path|
          DownstreamService.discard_from_draft_content_store(base_path)
        end
      end

      def delete_content_from_live_content_store(
        previous_content_store_base_paths,
        new_content_store_base_paths
      )
        previous_live_base_path =
          live_base_path_from_base_path_content_store_pairs(
            previous_content_store_base_paths
          )

        new_live_base_path =
          live_base_path_from_base_path_content_store_pairs(
            new_content_store_base_paths
          )

        if !previous_live_base_path.nil? &&
            previous_live_base_path != new_live_base_path

          Adapters::ContentStore.delete_content_item(
            previous_live_base_path
          )
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
          [:base_path, :locale] + ContentItem.new.attributes.keys.map(&:to_sym)
      end

      def delete_all(content_id)
        content_items = ContentItem.where(content_id: content_id)
        Services::DeleteContentItem.destroy_supporting_objects(content_items)
        content_items.destroy_all
      end
    end
  end
end
