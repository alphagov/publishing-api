Rails.application.routes.draw do
  scope format: false do |r|
    put "/draft-content(/*base_path)", to: "content_items#put_draft_content_item"
    put "/content(/*base_path)", to: "content_items#put_live_content_item"

    put "/publish-intent(/*base_path)", to: "publish_intents#create_or_update"
    get "/publish-intent(/*base_path)", to: "publish_intents#show"
    delete "/publish-intent(/*base_path)", to: "publish_intents#destroy"

    put "/paths(/*base_path)", to: "path_reservations#reserve_path"

    namespace :v2 do
      get "/content", to: "content_items#index"
      put "/content/:content_id", to: "content_items#put_content"
      get "/content/:content_id", to: "content_items#show"
      post "/content/:content_id/publish", to: "content_items#publish"
      post "/content/:content_id/discard-draft", to: "content_items#discard_draft"

      get "/links/:content_id", to: "link_sets#get_links"
      put "/links/:content_id", to: "link_sets#put_links"
    end
  end

  get '/healthcheck', :to => proc { [200, {}, ['OK']] }
end
