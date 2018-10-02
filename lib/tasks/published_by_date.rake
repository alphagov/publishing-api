require "csv"

desc %{
Finds content published within a given date range
Usage
rake 'published_by_date["2017-05-01","2017-05-03"]'
}
task :published_by_date, %i[from to] => :environment do |_, args|
  sql = <<-EOS
    select distinct events.created_at, editions.publishing_app, events.content_id, editions.base_path, editions.title
      from events
        join documents on documents.content_id = events.content_id
        join editions on editions.document_id = documents.id
      where events.action = 'Publish'
        and events.created_at >= '#{args[:from]}'
        and events.created_at <= '#{args[:to]}'
      order by publishing_app, created_at;
  EOS

  items = ActiveRecord::Base.connection.execute(sql)

  csv_out = CSV.new($stdout)
  csv_out << %w(publish_date publishing_app content_id base_path title)

  items.each do |i|
    csv_out << [i["created_at"], i["publishing_app"], i["content_id"], i["base_path"], i["title"]]
  end
end
