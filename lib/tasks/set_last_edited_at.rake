desc "Sets last_edited_at for each edition with the value from public_updated_at"
task set_last_edited_at: :environment do
  sql = "UPDATE content_items SET last_edited_at = public_updated_at;"

  ActiveRecord::Base.connection.execute(sql)
end
