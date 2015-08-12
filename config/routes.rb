Rails.application.routes.draw do
  with_options format: false do |r|
    r.put "/draft-content/*base_path", to: "content_items#put_draft_content_item"
    r.put "/content/*base_path", to: "content_items#put_live_content_item"

    r.put "/publish-intent/*base_path", to: "publish_intents#create_or_update"
    r.get "/publish-intent/*base_path", to: "publish_intents#show"
    r.delete "/publish-intent/*base_path", to: "publish_intents#destroy"
  end

  get '/healthcheck', :to => proc { [200, {}, ['OK']] }
end
