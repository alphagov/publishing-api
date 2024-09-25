namespace :special_routes do
  desc "Publish special routes (except the homepage)"
  task publish: :environment do
    SpecialRoutePublisher.publish_special_routes
  end

  desc "Publish all special routes for a single application"
  task :publish_for_app, [:app_name] => :environment do |_, args|
    SpecialRoutePublisher.publish_special_routes_for_app(args.app_name)
  end

  desc "Publish a single special route"
  task :publish_one_route, [:base_path] => :environment do |_, args|
    SpecialRoutePublisher.publish_one_route(args.base_path)
  end

  desc "Unpublish a single special route, with a type of 'gone' or 'redirect'"
  task :unpublish_one_route, %i[base_path alternative_path] => :environment do |_, args|
    SpecialRoutePublisher.unpublish_one_route(args.base_path, args.alternative_path)
  end

  desc "Publish the homepage"
  task publish_homepage: :environment do
    SpecialRoutePublisher.publish_homepage
  end
end
