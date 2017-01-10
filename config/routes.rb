Rails.application.routes.draw do
  scope format: false do
    put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
    get "/publish-intent(/*base_path)", to: "publish_intents#show"
    delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"

    put "/paths(/*base_path)", to: "path_reservations#reserve_path"

    post '/lookup-by-base-path', to: 'lookups#by_base_path'

    namespace :v2 do
      get "/content", to: "content#index"
      put "/content/:content_id", to: "content#put_content"
      get "/content/:content_id", to: "content#show"
      post "/content/:content_id/publish", to: "content#publish"
      post "/content/:content_id/unpublish", to: "content#unpublish"
      post "/content/:content_id/discard-draft", to: "content#discard_draft"

      get "/links/:content_id", to: "link_sets#get_links"
      get "/expanded-links/:content_id", to: "link_sets#expanded_links"
      patch "/links/:content_id", to: "link_sets#patch_links"
      # put is provided for backwards compatibility.
      put "/links/:content_id", to: "link_sets#patch_links"
      get "/linked/:content_id", to: "link_sets#get_linked"

      get "/linkables", to: "content#linkables"
      get "/new-linkables", to: "content#new_linkables"

      post "/actions/:content_id", to: "actions#create"
    end
  end

  get '/healthcheck', to: proc { [200, {}, ['OK']] }
  get '/debug/:content_id', to: "debug#show"
  get "/debug/experiments/:experiment", to: "debug#experiment"
end
