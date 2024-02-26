desc "Unpublishes /info page as part of the info-frontend retirement"
task tmp_unpublish_info_pages: :environment do
  info_page = Edition.live.find_by_base_path("/info")

  payload = {
    content_id: info_page.content_id,
    type: "gone",
    discard_drafts: true,
  }

  Commands::V2::Unpublish.call(payload)
end
