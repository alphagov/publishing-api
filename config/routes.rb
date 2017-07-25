Rails.application.routes.draw do
  def content_id_constraint(request)
    UuidValidator.valid?(request.params[:content_id])
  end

  scope format: false do
    put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
    get "/publish-intent(/*base_path)", to: "publish_intents#show"
    delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"

    put "/paths(/*base_path)", to: "path_reservations#reserve_path"

    post '/lookup-by-base-path', to: 'lookups#by_base_path'

    namespace :v2 do
      get "/content", to: "content_items#index"
      scope constraints: method(:content_id_constraint) do
        put "/content/:content_id", to: "content_items#put_content"
        get "/content/:content_id", to: "content_items#show"
        post "/content/:content_id/publish", to: "content_items#publish"
        post "/content/:content_id/unpublish", to: "content_items#unpublish"
        post "/content/:content_id/discard-draft", to: "content_items#discard_draft"
        post "/content/:content_id/import", to: "content_items#import"

        get "/links/:content_id", to: "link_sets#get_links"
        get "/expanded-links/:content_id", to: "link_sets#expanded_links"
        patch "/links/:content_id", to: "link_sets#patch_links"
        # put is provided for backwards compatibility.
        put "/links/:content_id", to: "link_sets#patch_links"
        get "/linked/:content_id", to: "link_sets#get_linked"
      end

      get "/editions", to: "editions#index"

      get "/linkables", to: "content_items#linkables"
      get "/new-linkables", to: "content_items#new_linkables"

      post "/actions/:content_id", to: "actions#create"
    end

    if ENV.include?("CONTENT_API_PROTOTYPE")
      namespace :content_api_prototype do
        namespace :content_items do
          scope constraints: method(:content_id_constraint) do
            get "/content/:content_id/:locale/:user_facing_version", to: "content#by_content_id"
          end
          get "/content(/*base_path)", to: "content#by_base_path"
        end
      end
    end
  end

  get '/healthcheck', to: proc { [200, {}, ['OK']] }
  get '/debug/:content_id', to: "debug#show"
  get "/debug/experiments/:experiment", to: "debug#experiment"

  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
