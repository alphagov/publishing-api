desc "Publish special routes (except the homepage)"
task publish_special_routes: :environment do
  Tasks::SpecialRoutePublisher.publish_special_routes
end

desc "Publish all special routes for a single application"
task :publish_special_routes_for_app, [:app_name] => :environment do |_, args|
  Tasks::SpecialRoutePublisher.publish_special_routes_for_app(args.app_name)
end

desc "Publish a single special route"
task :publish_one_special_route, [:base_path] => :environment do |_, args|
  Tasks::SpecialRoutePublisher.publish_one_route(args.base_path)
end

desc "Unpublish a single special route, with a type of 'gone' or 'redirect'"
task :unpublish_one_special_route, %i[base_path alternative_path] => :environment do |_, args|
  Tasks::SpecialRoutePublisher.unpublish_one_route(args.base_path, args.alternative_path)
end

desc "Publish the homepage"
task publish_homepage: :environment do
  Tasks::SpecialRoutePublisher.publish_homepage
end
