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
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PublishingAPI
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.eager_load_paths << "#{config.root}/app"
    config.eager_load_paths << "#{config.root}/lib"

    config.i18n.available_locales = %i[
      ar
      az
      be
      bg
      bn
      cs
      cy
      da
      de
      dr
      el
      en
      es
      es-419
      et
      fa
      fi
      fr
      gd
      gu
      he
      hi
      hr
      hu
      hy
      id
      is
      it
      ja
      ka
      kk
      ko
      lt
      lv
      ms
      mt
      ne
      nl
      no
      pa
      pa-pk
      pl
      ps
      pt
      ro
      ru
      si
      sk
      sl
      so
      sq
      sr
      sv
      sw
      ta
      th
      tk
      tr
      uk
      ur
      uz
      vi
      yi
      zh
      zh-hk
      zh-tw
    ]

    config.s3_export = OpenStruct.new(
      bucket: ENV["EVENT_LOG_AWS_BUCKETNAME"],
      events_key_prefix: "events/",
    )

    # This also configures session_options for use below
    config.session_store :cookie_store, key: "_interslice_session"

    # Required for all session management (regardless of session_store)
    config.middleware.use ActionDispatch::Cookies

    config.middleware.use config.session_store, config.session_options

    config.debug_exception_response_format = :api

    # Even though most GOV.UK apps use the London time_zone, publishing-api almost always wants to
    # present times in UTC, so we set that as the default time_zone
    initializer "publishing_api.configure_timezone",
                after: "govuk_app_config.configure_timezone",
                before: "active_support.initialize_time_zone" do
      config.time_zone = "UTC"
    end
  end
end
