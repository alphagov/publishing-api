namespace :data_hygiene do
  desc "Remove a change note from a document and represent to the content store."
  namespace :remove_change_note do
    def call_change_note_remover(content_id, locale, query, dry_run:)
      change_note = DataHygiene::ChangeNoteRemover.call(
        content_id, locale, query, dry_run: dry_run
      )

      if dry_run
        puts "Would have removed: #{change_note.inspect}"
      else
        puts "Removed: #{change_note.inspect}"
      end
    rescue DataHygiene::ChangeNoteNotFound
      puts "Could not find a change note."
    end

    task :dry, %i[content_id locale query] => :environment do |_, args|
      call_change_note_remover(args[:content_id], args[:locale], args[:query], dry_run: true)
    end

    task :real, %i[content_id locale query] => :environment do |_, args|
      call_change_note_remover(args[:content_id], args[:locale], args[:query], dry_run: false)
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
end
