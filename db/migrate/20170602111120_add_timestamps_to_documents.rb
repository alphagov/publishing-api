class AddTimestampsToDocuments < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    add_timestamps(:documents, null: true) unless column_exists?(:documents, :created_at)
    puts "> Timestamp fields added."
    puts "> Updating multiple-locale documents without editions..."

    update_multiple_locale_documents_without_editions
    puts "> Multiple-locale documents without editions updated."
    puts "> Updating remaining documents..."

    remaining_documents = Document.where(created_at: nil).count

    Document.where(created_at: nil).find_each.with_index do |document, index|
      editions = Edition.where(document_id: document.id).order(:user_facing_version)
      if editions.exists?
        update_timestamps_from_editions(document, editions)
      else
        update_timestamps_from_events(document)
      end
      puts "> #{index + 1}/#{remaining_documents} documents updated." if (index + 1) % 100 == 0
    end

    puts "> All remaining documents updated."
    puts "> Setting NOT NULL constraint on created_at and updated_at..."
    change_column_null :documents, :created_at, false
    change_column_null :documents, :updated_at, false
  end

  def down
    remove_column :documents, :created_at
    remove_column :documents, :updated_at
  end

private

  MULTIPLE_LOCALE_DOCUMENTS_WITHOUT_EDITIONS = [
    {
      content_id: "f091d705-8221-40c4-bc5d-2914c2d0763f",
      locale: "en",
      created_at: "Sun, 22 Jan 2017 10:46:37 UTC +00:00",
      updated_at: "Sun, 22 Jan 2017 10:55:43 UTC +00:00",
    },
    {
      content_id: "f091d705-8221-40c4-bc5d-2914c2d0763f",
      locale: "ar",
      created_at: "Sun, 22 Jan 2017 10:50:19 UTC +00:00",
      updated_at: "Sun, 22 Jan 2017 10:55:43 UTC +00:00",
    },
    {
      content_id: "0c0640e1-83e5-49a7-9da6-7ec3dfdf9936",
      locale: "es",
      created_at: "Mon, 13 Mar 2017 12:42:32 UTC +00:00",
      updated_at: "Mon, 13 Mar 2017 14:29:05 UTC +00:00",
    },
    {
      content_id: "ca74cbbc-7c20-4e28-a3e0-b003490a162d",
      locale: "en",
      created_at: "Wed, 12 Apr 2017 05:51:27 UTC +00:00",
      updated_at: "Wed, 12 Apr 2017 08:12:07 UTC +00:00",
    },
    {
      content_id: "ca74cbbc-7c20-4e28-a3e0-b003490a162d",
      locale: "ar",
      created_at: "Wed, 12 Apr 2017 07:19:55 UTC +00:00",
      updated_at: "Wed, 12 Apr 2017 08:12:07 UTC +00:00",
    },
    {
      content_id: "5f525430-7631-11e4-a3cb-005056011aef",
      locale: "ar",
      created_at: "Thu, 13 Apr 2017 17:13:09 UTC +00:00",
      updated_at: "Thu, 13 Apr 2017 17:13:20 UTC +00:00",
    },
    {
      content_id: "602c5c4a-7631-11e4-a3cb-005056011aef",
      locale: "cy",
      created_at: "Wed, 22 Feb 2017 16:07:01 UTC +00:00",
      updated_at: "Tue, 21 Mar 2017 08:23:42 UTC +00:00",
    },
    {
      content_id: "6d93eff6-7bac-4368-9247-a6c3107baa42",
      locale: "en",
      created_at: "Tue, 28 Mar 2017 06:08:15 UTC +00:00",
      updated_at: "Wed, 29 Mar 2017 06:38:39 UTC +00:00",
    },
    {
      content_id: "6d93eff6-7bac-4368-9247-a6c3107baa42",
      locale: "zh",
      created_at: "Tue, 28 Mar 2017 06:21:57 UTC +00:00",
      updated_at: "Wed, 29 Mar 2017 06:38:39 UTC +00:00",
    },
  ]

  def update_multiple_locale_documents_without_editions
    MULTIPLE_LOCALE_DOCUMENTS_WITHOUT_EDITIONS.each do |data|
      document = Document.find_by(content_id: data[:content_id], locale: data[:locale])
      next unless document
      update_timestamps(document, data[:created_at], data[:updated_at])
    end
  end

  def update_timestamps_from_events(document)
    created_at = Event.where(content_id: document.content_id).minimum(:created_at)
    updated_at = Event.where(content_id: document.content_id).maximum(:created_at)
    update_timestamps(document, created_at, updated_at)
  end

  def update_timestamps_from_editions(document, editions)
    created_at = editions.first.created_at
    updated_at = editions.last.created_at
    update_timestamps(document, created_at, updated_at)
  end

  def update_timestamps(document, created_at, updated_at)
    Document.transaction do
      document.reload
      document.created_at ||= created_at
      document.updated_at ||= updated_at
      document.save
    end
  end
end
