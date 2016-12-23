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

        delete_all(payload[:content_id])
        payload[:history].map.with_index do |event, index|
          create_content_item(event, index, payload[:content_id])
        end

        after_transaction_commit do
          Commands::V2::RepresentDownstream.new.call(
            payload[:content_id],
            true
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
        # The unpublished state requires extra information, but all
        # other states don't
        return if ["draft", "published", "superseded"].include?(state_info)

        state_name = state_info[:name]

        if state_name == "unpublished"
          content_item.unpublish(
            state_info.slice(
              *%i(type explanation alternative_path unpublished_at)
            )
          )
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

        supported_states = ["draft", "published", "unpublished", "superseded"]

        unless supported_states.include?(state_name)
          raise CommandError.new(
            code: 422,
            message: "Unsupported state used at index #{index}: \
                      #{history_entry[:state]}, \
                      only #{supported_states} are supported"
          )
        end
      end

      def attributes
        @attributes ||=
          [:base_path, :locale] + ContentItem.new.attributes.keys.map(&:to_sym)
      end

      def delete_all(content_id)
        Services::DeleteContentItem.destroy_content_items_with_links(content_id)
      end
    end
  end
end
