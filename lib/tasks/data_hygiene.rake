namespace :data_hygiene do
  namespace :remove_change_note do
    desc "Remove a change note from a document and represent to the content store (dry run)"
    task :dry, %i[content_id locale query] => :environment do |_, args|
      change_note = DataHygiene::ChangeNoteRemover.call(
        args[:content_id], args[:locale], args[:query], dry_run: true
      )

      puts "Would have removed: #{change_note.inspect}"
    end

    desc "Remove a change note from a document and represent to the content store (for reals)"
    task :real, %i[content_id locale query] => :environment do |_, args|
      change_note = DataHygiene::ChangeNoteRemover.call(
        args[:content_id], args[:locale], args[:query], dry_run: false
      )

      puts "Removed: #{change_note.inspect}"
    end
  end

  desc "Check the status of a document whether it's in Content Store or Router."
  task :document_status_check, %i[content_id locale] => :environment do |_, args|
    document = Document.find_by!(args.to_hash)
    status = DataHygiene::DocumentStatusChecker.new(document)

    content_store = status.content_store?
    router = status.router?

    puts "Has the document made it to:"
    puts "Content Store? #{content_store ? 'Yes' : 'No'}"
    puts "Router? #{router ? 'Yes' : 'No'}"

    unless content_store && router
      puts ""
      puts "You could try running:"
      puts "rake 'represent_downstream:content_id[#{args[:content_id]}]'"
    end
  end

  desc "Removes invalid about page drafts from world organisations that can prevent editing"
  task remove_invalid_worldorg_drafts: :environment do
    about_pages = Edition
                    .where(document_type: "about", state: "draft")
                    .select { |edition| edition.base_path =~ /\A\/world\/organisations\/[^\/]+\z/ }
                    .map { |edition| [edition.document.content_id, edition.document.locale] }

    puts "Found #{about_pages.size} invalid draft Worldwide Organisation editions to remove"
    about_pages.each do |content_id, locale|
      puts "Removing draft edition #{content_id}"
      Commands::V2::DiscardDraft.call(
        {
          content_id:,
          locale:,
        },
      )
    end
  end

  desc "Bulk update the organisations associated with documents."
  task :bulk_update_organisation, %i[csv_filename] => :environment do |_, args|
    DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
  end
end
