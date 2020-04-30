require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PublishingAPI
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :classic
    # FIXME: Autoloader is only set to classic while restructuring work is undertaken.

    config.api_only = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.eager_load_paths << "#{config.root}/app"
    # FIXME: the 3 lines below will be uncommented as part of the restructuring work.
    # config.eager_load_paths += Dir["#{config.root}/app/queries"]
    # config.eager_load_paths += Dir["#{config.root}/app/commands"]
    # config.eager_load_paths += Dir["#{config.root}/app/presenters"]
    config.eager_load_paths << "#{config.root}/lib"

    config.i18n.available_locales = %i[
      en ar az be bg bn cs cy da de dr el
      es es-419 et fa fi fr gd he hi hr hu
      hy id is it ja ka kk ko lt lv ms mt nl
      no pl ps pt ro ru si sk sl so sq sr
      sv sw ta th tk tr uk ur uz vi zh zh-hk
      zh-tw
    ]

    config.s3_export = OpenStruct.new(
      bucket: ENV["EVENT_LOG_AWS_BUCKETNAME"],
      events_key_prefix: "events/",
    )

    config.debug_exception_response_format = :api
  end
end
