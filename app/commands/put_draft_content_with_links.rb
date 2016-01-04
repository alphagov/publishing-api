module Commands
  class PutDraftContentWithLinks < PutContentWithLinks
    def call
      if content_item[:content_id]
        draft_content_item = create_or_update_draft_content_item!
        create_or_update_links!
      end

      PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

      if downstream
        if (access_limit = AccessLimit.find_by(target: draft_content_item))
          attributes = content_item.merge(
            access_limited: {
              users: access_limit.users
            }
          )
        else
          attributes = content_item
        end

        payload = Presenters::DownstreamPresenter::V1.present(
          attributes,
          update_type: false,
        )
        Adapters::DraftContentStore.put_content_item(base_path, payload)
      end

      Success.new(content_item)
    end

  private

    def create_or_update_draft_content_item!
      DraftContentItem.create_or_replace(content_item_attributes) do |item|
        SubstitutionHelper.clear_draft!(item)

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

        item.assign_attributes_with_defaults(content_item_attributes)
      end
    end

    def access_limit_params
      payload[:access_limited]
    end
  end
end
