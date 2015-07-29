Rails.application.routes.draw do
  get '/healthcheck', :to => proc { [200, {}, ['OK']] }

  put "/draft-content/*base_path", to: "content_items#put_draft_content_item"
  put "/content/*base_path", to: "content_items#put_live_content_item"

  put "/publish-intent/*base_path", to: "publish_intents#create_or_update"
  get "/publish-intent/*base_path", to: "publish_intents#show"
  delete "/publish-intent/*base_path", to: "publish_intents#destroy"
end
