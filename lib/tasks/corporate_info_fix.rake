desc "Fix a base_path issue with some corporate info pages"
task corporate_info_fix: :environment do
  require_relative "../../db/migrate/helpers/delete_content"

  Edition.where(schema_name: "corporate_information_page").find_each do |e|
    next if e.locale != "cy" || e.base_path.end_with?(".cy")

    (puts [e.base_path, e.locale].inspect && next) if ENV["DRY_RUN"]

    #this edition has an en base_path but a cy locale
    edition_with_incorrect_base_path = e
    edition_with_incorrect_base_path.base_path += ".cy"

    route = edition_with_incorrect_base_path.routes.first
    route[:path] = edition_with_incorrect_base_path.base_path
    edition_with_incorrect_base_path.routes = [route]

    begin
      edition_with_incorrect_base_path.save!
    rescue ActiveRecord::RecordInvalid => e
      content_id = e.message.match(/content_id=([^\s]+)/)[1]
      documents = Document.where(content_id: content_id)

      raise "didn't expect more than one doc" if documents.count > 1

      editions = documents.first.editions
      raise "didn't expect more than one edition" if editions.count > 1

      edition = editions.first

      raise "expected redirect" unless edition.schema_name == "redirect"
      raise "expected en" unless edition.locale == "en"
      raise "expected matching base_path" if edition.base_path != edition_with_incorrect_base_path.base_path

      puts "deleting #{content_id}"
      Helpers::DeleteContent.destroy_documents_with_links(content_id)
    end
  end
end
