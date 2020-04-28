desc "Backfill new jsonb columns with data from original json columns"
task backfill_new_jsonb_columns: :environment do
  sql = "UPDATE editions SET temp_details = details, temp_routes = routes, temp_redirects = redirects WHERE id in (SELECT id FROM editions WHERE temp_details IS NULL OR temp_routes IS NULL OR temp_redirects IS NULL LIMIT 1000);"

  num = (Edition.count / 1000) + 1
  num.times do |i|
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished editions batch #{i}"
  end

  sql = "UPDATE events SET temp_payload = payload WHERE id in (SELECT id FROM events WHERE temp_payload IS NULL LIMIT 1000);"

  num = (Event.count / 1000) + 1
  num.times do |i|
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished events batch #{i}"
  end

  sql = "UPDATE unpublishings SET temp_redirects = redirects WHERE id in (SELECT id FROM unpublishings WHERE temp_redirects IS NULL AND redirects IS NOT NULL LIMIT 1000);"

  num = (Unpublishing.count / 1000) + 1
  num.times do |i|
    ActiveRecord::Base.connection_pool.with_connection { |con| con.exec_query(sql) }
    puts "finished unpublishings batch #{i}"
  end
end
