class SpecialRoutePublisher
  def self.publish_special_routes
    new.publish_routes(load_special_routes)
  end

  def self.publish_special_routes_for_app(app_name)
    routes = load_special_routes.filter { |r| r[:rendering_app] == app_name }

    if routes.any?
      new.publish_routes(routes)
    else
      Rails.logger.info("No routes for #{app_name} in lib/data/special_routes.yaml")
    end
  end

  def self.publish_one_route(base_path)
    route = load_special_routes.find { |r| r[:base_path] == base_path }

    if route
      new.publish_routes([route])
    else
      Rails.logger.info("Route needs to be added to /lib/data/special_routes.yaml")
    end
  end

  def self.unpublish_one_route(base_path, alternative_path = nil)
    route = load_special_routes.find { |r| r[:base_path] == base_path }

    if route && alternative_path
      Commands::V2::Unpublish.call({ content_id: route.fetch(:content_id), type: "redirect", alternative_path: })
    elsif route
      Commands::V2::Unpublish.call({ content_id: route.fetch(:content_id), type: "gone" })
    else
      Rails.logger.info("Route needs to be added to /lib/data/special_routes.yaml")
    end
  end

  def self.publish_homepage
    new.publish_routes(load_homepage)
  end

  def publish_route(route)
    routes = get_routes(route)

    routes.each { |r| Rails.logger.info("Publishing #{r[:type]} route #{r[:path]}, routing to #{route.fetch(:rendering_app)}...") }

    content_id = route.fetch(:content_id)

    # Always request a path reservation before publishing the special route,
    # with the flag to override any existing publishing app.
    # This allows for routes that were previously published by other apps to
    # be added to `special_routes.yaml` and "just work".
    # Commands::ReservePath.call(path_item)
    Commands::ReservePath.call({
      base_path: route.fetch(:base_path),
      publishing_app: "publishing-api",
      override_existing: true,
    })

    Commands::V2::PutContent.call({
      content_id:,
      base_path: route.fetch(:base_path),
      document_type: route.fetch(:document_type, "special_route"),
      schema_name: route.fetch(:document_type, "special_route"),
      title: route.fetch(:title),
      description: route.fetch(:description, ""),
      locale: route.fetch(:locale, "en"),
      details: {},
      routes:,
      publishing_app: "publishing-api",
      rendering_app: route.fetch(:rendering_app),
      public_updated_at: Time.zone.now.iso8601,
      update_type: route.fetch(:update_type, "major"),
    })

    if route[:links]
      Commands::V2::PatchLinkSet.call({ content_id:, links: route[:links] })
    end

    Commands::V2::Publish.call({ content_id:, update_type: nil, locale: route.fetch(:locale, "en") })
  end

  def get_routes(route)
    routes = [
      {
        path: route.fetch(:base_path),
        type: route.fetch(:type, "exact"),
      },
    ]

    routes + route.fetch(:additional_routes, []).map { |ar| { path: ar[:base_path], type: ar.fetch(:type, "exact") } }
  end

  def publish_routes(routes)
    routes.each { |r| publish_route(r) }
  end

  def self.load_special_routes
    load_all_special_routes.reject { |r| r.fetch(:document_type, nil) == "homepage" }
  end

  def self.load_homepage
    load_all_special_routes.select { |r| r.fetch(:document_type, nil) == "homepage" }
  end

  def self.load_all_special_routes
    YAML.load_file(Rails.root.join("lib/data/special_routes.yaml"))
  end
end
