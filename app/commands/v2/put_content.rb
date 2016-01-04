module Commands
  module V2
    class PutContent < BaseCommand
      def call
        validate_version_lock!

        content_item = create_or_update_draft_content_item!

        PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

        if downstream
          draft_payload = Presenters::ContentStorePresenter.present(content_item)
          ContentStoreWorker.perform_async(
            content_store: Adapters::DraftContentStore,
            base_path: base_path,
            payload: draft_payload,
          )
        end

        handle_path_change(content_item)

        response_hash = Presenters::Queries::ContentItemPresenter.present(content_item)
        Success.new(response_hash)
      end

    private
      def validate_version_lock!
        super(DraftContentItem, content_id, payload[:previous_version])
      end

      def content_id
        payload.fetch(:content_id)
      end

      def access_limit_params
        payload[:access_limited]
      end

      def create_or_update_draft_content_item!
        DraftContentItem.create_or_replace(content_item_attributes) do |item|
          SubstitutionHelper.clear_draft!(item)

          item.assign_attributes_with_defaults(content_item_attributes)

          if item.valid?
            version = Version.find_or_initialize_by(target: item)
            version.increment
            version.save!

            if access_limit_params && (users = access_limit_params[:users])
              AccessLimit.create(
                target: item,
                users: users
              )
            end
          end
        end
      end

      def content_item_attributes
        payload.slice(*DraftContentItem::TOP_LEVEL_FIELDS)
      end

      def handle_path_change(content_item)
        path_change = content_item.previous_changes[:base_path]
        if path_change.present? && path_change[0].present?
          if content_item.live_content_item.present?
            RedirectHelper.create_redirect(
              publishing_app: content_item.publishing_app,
              old_base_path: path_change[0],
              new_base_path: path_change[1],
              locale: content_item.locale,
            )
          else
            ContentStoreWorker.perform_async(
              content_store: Adapters::DraftContentStore,
              base_path: path_change[0],
              delete: true,
            )
          end
        end
      end
    end
  end
end
