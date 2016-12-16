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
        payload[:content_items].map.with_index do |event, index|
          create_content_item(event, index, payload[:content_id])
        end

        after_transaction_commit do
          Commands::V2::RepresentDownstream.new.call(
            ContentItem.where(content_id: payload[:content_id])
          )
        end

        Success.new(content_id: payload[:content_id])
      end

    private

      def create_content_item(event, index, content_id)
        event_payload = event[:payload]
        content_item_payload = event_payload.except(:state)

        validate_content_item_payload(content_item_payload)

        Services::CreateContentItem.new(
          payload: content_item_payload.merge(content_id: content_id),
          user_facing_version: index + 1,
          lock_version: index + 1,
          state: event_payload[:state]
        ).create_content_item
      end

      def validate_content_item_payload(content_item_payload)
        unrecognised_attributes = content_item_payload.keys - attributes

        unless unrecognised_attributes.empty?
          raise CommandError.new(
            code: 422,
            message: "Unrecognised attributes in payload: #{unrecognised_attributes}"
          )
        end

        schema_validator = SchemaValidator.new(payload: content_item_payload)

        unless schema_validator.valid?
          raise CommandError.new(
            code: 422,
            message: "Schema validation failed: #{schema_validator.errors}",
            error_details: schema_validator.errors
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
