Rails.application.routes.draw do
  get "/healthcheck" => proc { [200, {}, ["OK\n"]] }
end
