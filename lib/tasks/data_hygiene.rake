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

  desc "Check the status of a document whether it's in Content Store"
  task :document_status_check, %i[content_id locale] => :environment do |_, args|
    document = Document.find_by!(args.to_hash)
    status = DataHygiene::DocumentStatusChecker.new(document)

    content_store = status.content_store?

    puts "Has the document made it to:"
    puts "Content Store? #{content_store ? 'Yes' : 'No'}"

    unless content_store
      puts ""
      puts "You could try running:"
      puts "rake 'represent_downstream:content_id[#{args[:content_id]}]'"
    end
  end

  desc "Bulk update the organisations associated with documents."
  task :bulk_update_organisation, %i[csv_filename] => :environment do |_, args|
    DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
  end

  desc "Discard drafts (if present) and unpublish"
  task :discard_drafts_and_unpublish, %i[content_id] => :environment do |_, args|
    abort("Missing parameter: content_id") if args[:content_id].blank?

    documents = Document.where(content_id: args[:content_id])
    abort("Content ID #{args[:content_id]} not found") unless documents.any?

    documents.each do |document|
      if document.draft.present?
        Commands::V2::DiscardDraft.call(
          {
            content_id: document.content_id,
            locale: document.locale,
          },
        )
      end

      Commands::V2::Unpublish.call(
        {
          content_id: document.content_id,
          locale: document.locale,
          type: "gone",
        },
      )
    end
  end
end
