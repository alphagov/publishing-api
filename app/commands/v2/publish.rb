module Commands
  module V2
    class Publish < BaseCommand
      def call
        validate!

        draft = lookup_content_item
        publish_content_item(draft)

        Success.new(content_id: content_id)
      end

    private
      def validate!
        validate_update_type!
        validate_version_lock!
      end

      def validate_update_type!
        raise CommandError.new(
          code: 422,
          message: "update_type is required",
          error_details: {
            error: {
              code: 422,
              message: "update_type is required",
              fields: {
                update_type: ["is required"],
              }
            }
          }
        ) unless update_type.present?
      end

      def validate_version_lock!
        super(DraftContentItem, content_id, payload[:previous_version])
      end

      def content_id
        payload[:content_id]
      end

      def locale
        payload[:locale] || DraftContentItem::DEFAULT_LOCALE
      end

      def update_type
        payload[:update_type]
      end

      def lookup_content_item
        draft = DraftContentItem.find_by(content_id: content_id, locale: locale)

        unless draft
          message = "Item with content_id #{content_id} and locale #{locale} does not exist"
          raise CommandError.new(code: 404, message: message)
        end

        draft
      end

      def publish_content_item(draft_content_item)
        attributes = build_live_attributes(draft_content_item)

        live_content_item = LiveContentItem.create_or_replace(attributes) do |live_item|
          SubstitutionHelper.clear_live!(live_item)

          live_version = Version.find_or_initialize_by(target: live_item)
          draft_version = Version.find_or_initialize_by(target: draft_content_item)

          if live_version.number == draft_version.number
            raise CommandError.new(code: 400, message: "This item is already published")
          else
            live_version.copy_version_from(draft_content_item)
            live_version.save! if live_item.valid?
          end
        end

        live_content_item.increment_receipt_order

        if downstream
          ContentStoreWorker.perform_in(
            1.second,
            content_store: Adapters::ContentStore,
            live_content_item_id: live_content_item.id,
          )

          queue_payload = Presenters::MessageQueuePresenter.present(live_content_item, update_type: update_type)
          PublishingAPI.service(:queue_publisher).send_message(queue_payload)
          handle_path_change(live_content_item)
        end
      end

      def build_live_attributes(draft_content_item)
        attributes = draft_content_item
          .attributes
          .merge(draft_content_item: draft_content_item)

        unless attributes[:public_updated_at] || update_type != "major"
          attributes = attributes.merge(public_updated_at: DateTime.now)
        end

        attributes
      end

      def handle_path_change(live_content_item)
        path_change = live_content_item.previous_changes[:base_path]
        if path_change.present? && path_change[0].present?
          draft_redirect = DraftContentItem.find_by(format: "redirect", base_path: path_change[0])
          self.class.call(
            content_id: draft_redirect.content_id,
            locale: draft_redirect.locale,
            update_type: "major"
          ) if draft_redirect.present?
        end
      end
    end
  end
end
