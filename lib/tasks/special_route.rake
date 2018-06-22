namespace :special_route do
  # This task is used to add a special route to the Publishing API
  # It is only intended for simple ones that have a single route, if you have
  # more than that you should write a task for that job
  # It is also only intended to be used in situations where there is not an
  # actual publishing application associated with the content as otherwise
  # that publishing application should speak to the Publishing API itself
  #
  # To use call rake special_route:draft[/path, 'Content title', app-to-render)
  #
  # You can also pass in the route type and content_id if you have those
  desc "Create a draft special route"
  # rubocop:disable Metrics/BlockLength
  task :draft, %i(base_path title rendering_app route_type content_id) => :environment do |_, args|
    base_path = args.fetch(:base_path)
    content_id = args.fetch(:content_id, SecureRandom.uuid)
    begin
      Commands::V2::PutContent.call(
        base_path: base_path,
        content_id: content_id,
        document_type: "special_route",
        publishing_app: "publishing-api",
        rendering_app: args.fetch(:rendering_app),
        routes: [
          {
            path: args.fetch(:base_path),
            type: args.fetch(:route_type, "prefix"),
          }
        ],
        schema_name: "special_route",
        title: args.fetch(:title),
        update_type: "major",
      )

      puts ""
      puts "Draft document created with content_id of #{content_id}"
      puts "This will be available at #{Plek.find('draft-origin', external: true) + base_path}"
      puts "To publish this run `bundle exec rake publish[#{content_id}]`"
      puts "To discard this draft this run `bundle exec rake discard_draft[#{content_id}]`"
    rescue CommandError => e
      puts "Error: #{e.message}"
      pp e.error_details
      exit 1
    end
    # rubocop:enable Metrics/BlockLength
  end
end
