namespace :data_cleanup do
  desc "Removes drafts for specialist publisher documents if they're duplicates"
  task remove_substitutions: :environment do
    attributes = Unpublishing
      .where(type: "substitute")
      .joins(:content_item)
      .pluck(:edition_id, :content_id)

    edition_ids, content_ids = attributes
      .flatten
      .partition
      .with_index { |_, index| index.even? }

    puts "Removing #{edition_ids.count} content items"

    supporting_classes = [
      AccessLimit,
      Linkable,
      Location,
      State,
      Translation,
      Unpublishing,
      UserFacingVersion
    ]

    supporting_classes.each do |klass|
      puts "-- Removing all associated #{klass} objects"
      klass.where(edition_id: edition_ids).destroy_all
    end

    LockVersion.where(
      target_id: edition_ids,
      target_type: "Edition"
    ).destroy_all

    Edition.where(id: edition_ids).destroy_all

    puts "Checking link sets"
    content_ids.each do |content_id|
      # Remove linkset if there's no content items left
      # for that content ID.
      unless Edition.exists?(content_id: content_id)
        puts "-- Removing orphaned LinkSet for content ID '#{content_id}'"
        LinkSet.where(content_id: content_id).destroy_all
      end
    end
  end
end
