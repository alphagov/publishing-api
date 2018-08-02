require_relative 'boot'

require "rails"
# Pick the frameworks you want:
# require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_view/railtie"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PublishingAPI
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.api_only = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.eager_load_paths << "#{config.root}/app"
    config.eager_load_paths << "#{config.root}/lib"
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    config.i18n.available_locales = [
      :en, :ar, :az, :be, :bg, :bn, :cs, :cy, :de, :dr, :el, :es, :'es-419',
      :et, :fa, :fr, :he, :hi, :hu, :hy, :id, :it, :ja, :ka, :ko, :lt,
      :lv, :ms, :pl, :ps, :pt, :ro, :ru, :si, :sk, :so, :sq, :sr, :sw, :ta, :th,
      :tk, :tr, :uk, :ur, :uz, :vi, :zh, :'zh-hk', :'zh-tw'
    ]

    config.s3_export = OpenStruct.new(
      bucket: ENV["EVENT_LOG_AWS_BUCKETNAME"],
      events_key_prefix: "events/",
    )

    config.debug_exception_response_format = :api
  end
end
