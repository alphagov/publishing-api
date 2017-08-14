require_relative "../../db/migrate/helpers/delete_content"

namespace :tmp do
  task fix_invalid_document: :environment do
    document_created_by_whitehall_bug_content_id = "a8364f44-3f21-43e5-8351-d150fb177649"
    Helpers::DeleteContent.destroy_documents_with_links([document_created_by_whitehall_bug_content_id])

    #this edition has an en base_path but a cy locale
    edition_with_incorrect_base_path = Edition.find(2676794)
    edition_with_incorrect_base_path.base_path = "/government/organisations/land-registry/about/recruitment.cy"

    route = edition_with_incorrect_base_path.routes.first
    route[:path] = edition_with_incorrect_base_path.base_path
    edition_with_incorrect_base_path.routes = [route]

    edition_with_incorrect_base_path.save!
  end
end
