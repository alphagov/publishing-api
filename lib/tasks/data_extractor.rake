namespace :data_extractor do
  desc "Creates a CSV with with the links data of all the Whitehall items"
  namespace :list_tagged_items do
    task whitehall: :environment do
      # Expected output format:
      # format,tag_type,count
      # content-id-0000-0001,policy_areas,10
      # content-id-0000-0002,organisations,2

      sql = "select content_items.content_id, links.link_type, count(*) " \
      "from states " \
      "join content_items on states.content_item_id = content_items.id " \
      "join link_sets on ( link_sets.content_id = content_items.content_id ) " \
      "join links on ( links.link_set_id = link_sets.id ) " \
      "where states.name = 'published'" \
      "and content_items.publishing_app = 'whitehall'" \
      "group by content_items.content_id, links.link_type " \
      "order by content_items.content_id, links.link_type DESC"

      items = ActiveRecord::Base.connection.execute(sql)

      csv_out = CSV.new($stdout)
      csv_out << %w(format tag_type count)
      items.each do |i|
        csv_out << [i["content_id"], i["link_type"], i["count"]]
      end
    end
  end
end
