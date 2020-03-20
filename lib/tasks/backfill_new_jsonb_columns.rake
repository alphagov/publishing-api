desc "Migrate access_limits json columns"
task access_limits: :environment do
  puts "starting access limits"
  acc_lim_sql = "UPDATE access_limits SET temp_users = users, temp_organisations = organisations;"
  ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(acc_lim_sql) }
end

desc "Migrate editions json columns"
task editions: :environment do
  record = Edition.find_by(id: 704530)
  details = record.details.to_json.gsub(/\\u0000/, "")
  details = JSON.parse(details).symbolize_keys
  record.update(details: details)

  low = 0
  high = 1000
  total = Edition.maximum("id")

  sql = "UPDATE editions SET temp_details = details, temp_routes = routes, " \
        "temp_redirects = redirects WHERE id > #{low} AND id <= #{high};"

  while high < total
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished editions batch #{low} to #{high}"
    low += 1000
    high += 1000
  end
end

desc "Migrate events json columns"
task events: :environment do
  event = Event.find_by(id: 31148138)
  payload = event.payload.to_json.gsub(/\\u0000/, "")
  payload = JSON.parse(payload).symbolize_keys
  event.update(payload: payload)

  low = 0
  high = 1000
  total = Event.maximum("id")

  sql = "UPDATE events SET temp_payload = payload WHERE id > #{low} AND id <= #{high};"

  while high < total
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished events batch #{low} to #{high}"
    low += 1000
    high += 1000
  end
end

desc "Migrate expanded_links json columns"
task expanded_links: :environment do
  low = 0
  high = 1000
  total = ExpandedLinks.maximum("id")

  sql = "UPDATE expanded_links SET temp_expanded_links = expanded_links " \
        "WHERE id > #{low} AND id <= #{high};"

  while high < total
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished expanded links batch #{low} to #{high}"
    low += 1000
    high += 1000
  end
end

desc "Migrate unpublishings json columns"
task unpublishings: :environment do
  low = 0
  high = 1000
  total = Unpublishing.maximum("id")

  sql = "UPDATE unpublishings SET temp_redirects = redirects WHERE id > #{low} AND id <= #{high};"

  while high < total
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished unpublishings batch #{low} to #{high}"
    low += 1000
    high += 1000
  end
end

desc "Backfill new jsonb columns with data from original json columns"
task backfill_new_jsonb_columns: :environment do
  Rake::Task[:access_limits].invoke
  Rake::Task[:editions].invoke
  Rake::Task[:events].invoke
  Rake::Task[:expanded_links].invoke
  Rake::Task[:unpublishings].invoke
end
