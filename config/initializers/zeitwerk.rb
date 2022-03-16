ActiveSupport::Dependencies.autoload_paths.delete(Rails.root.join("app/adapters").to_s)
ActiveSupport::Dependencies.autoload_paths.delete(Rails.root.join("app/commands").to_s)
ActiveSupport::Dependencies.autoload_paths.delete(Rails.root.join("app/presenters").to_s)
ActiveSupport::Dependencies.autoload_paths.delete(Rails.root.join("app/queries").to_s)
