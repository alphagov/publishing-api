namespace :linkables do
  desc "Populates the linkables table"
  task populate: :environment do
    scope = ContentItem.all
    scope = Translation.filter(scope, locale: "en")
    scope = State.filter(scope, name: %w[published draft])
    scope = Location.join_content_items(scope)
    scope = UserFacingVersion.join_content_items(scope)
                                                                     # state  version
    scope = scope.select(:id, :content_id, :document_type, :base_path, :name, :number)

    scope.find_each do |ci|
      if ci.name == "draft" && ci.number == 1
        # Never published
        puts "Creating draft linkable for #{ci.document_type} ##{ci.id} (#{ci.content_id})"
        unless Linkable.exists?(base_path: ci.base_path)
          Linkable.create!(
            content_item_id: ci.id,
            base_path: ci.base_path,
            document_type: ci.document_type,
            state: "draft",
          )
        end
      elsif ci.name == "published"
        puts "Creating published linkable for #{ci.document_type} ##{ci.id} (#{ci.content_id})"
        unless Linkable.exists?(base_path: ci.base_path)
          Linkable.create!(
            content_item_id: ci.id,
            base_path: ci.base_path,
            document_type: ci.document_type,
            state: "published",
          )
        end
      end

      # If the content item is redrafted we don't
      # want to create a linkable with draft
      # content if there's a live one available,
      # so we do nothing and wait for the published
      # one to come around.
    end
  end
end
