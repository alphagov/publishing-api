Rails.application.routes.draw do
  def content_id_constraint(request)
    UuidValidator.valid?(request.params[:content_id])
  end

  require "sidekiq/web"

  scope format: false do
    put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
    get "/publish-intent(/*base_path)", to: "publish_intents#show"
    delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"

    put "/paths(/*base_path)", to: "path_reservations#reserve_path"
    delete "/paths(/*base_path)", to: "path_reservations#unreserve_path"

    post "/lookup-by-base-path", to: "lookups#by_base_path"

    get "/graphql/content/*path_without_root" => "graphql#content"
    post "/graphql", to: "graphql#execute"

    namespace :v2 do
      get "/content", to: "content_items#index"
      scope constraints: method(:content_id_constraint) do
        put "/content/:content_id", to: "content_items#put_content"
        get "/content/:content_id", to: "content_items#show"
        get "/content/:content_id/host-content", to: "content_items#host_content"
        get "/content/:content_id/host-content/:host_content_id", to: "content_items#host_content_item"
        # Point legacy `embedded` endpoint to `host_content` endpoint
        get "/content/:content_id/embedded", to: "content_items#host_content"
        get "/content/:content_id/events", to: "content_items#events"
        post "/content/:content_id/publish", to: "content_items#publish"
        post "/content/:content_id/republish", to: "content_items#republish"
        post "/content/:content_id/unpublish", to: "content_items#unpublish"
        post "/content/:content_id/discard-draft", to: "content_items#discard_draft"

        get "/links/:content_id", to: "link_sets#get_links"
        get "/expanded-links/:content_id", to: "link_sets#expanded_links"
        patch "/links/:content_id", to: "link_sets#patch_links"
        get "/linked/:content_id", to: "link_sets#get_linked"
      end

      post "/links/by-content-id", to: "link_sets#bulk_links"

      get "/editions", to: "editions#index"

      get "/linkables", to: "content_items#linkables"

      get "/links/changes", to: "link_changes#index"

      resources :schemas, only: %i[index show]
    end
  end

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::ActiveRecord,
    GovukHealthcheck::SidekiqRedis,
  )

  mount Sidekiq::Web => "/sidekiq"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
