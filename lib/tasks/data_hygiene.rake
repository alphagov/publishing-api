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

  desc "Unpublish remaining whitehall-frontend rendered editions"
  task unpublish_whitehall_frontend: :environment do
    whitehall_frontend_documents = Edition
                                    .where(state: "published", rendering_app: "whitehall-frontend")
                                    .map { |edition| edition.document.content_id }

    whitehall_frontend_documents.each do |content_id|
      Commands::V2::Unpublish.call(
        {
          content_id: content_id,
          type: "gone",
        },
      )
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

  desc "Bulk update the organisations associated with documents."
  task :bulk_update_organisation, %i[csv_filename] => :environment do |_, args|
    DataHygiene::BulkOrganisationUpdater.call(args[:csv_filename])
  end
end
