class DeleteProblematicTranslations < ActiveRecord::Migration[5.0]
  def change
  	require_relative '/var/apps/publishing-api/db/migrate/helpers/delete_content.rb'

		ids_tbd = [
			"7f138690-b166-416d-a71c-59448c4d13fc",
			"c6d860e1-af7e-49fc-99ba-b1be4881c804",
			"694d3b23-3499-4672-aa53-c6e179ae9743", 
			"056ab5a5-2fb4-4b20-b028-eb182aa7e5c4",
			"8d435ed2-8743-4e07-9800-5b24318e5d87",
			"0243d2dd-0581-4186-b41a-b521b8368194",
			"0e526f62-0bc7-4ff5-ae97-a3990551253d",
			"755db6ab-b06b-48ba-ab0e-07ea9edb4d45",
			"125c8fb9-04fe-4e64-a562-88e241e36db0",
			"eb5a4ddb-ab6f-468b-80a7-5078db98861a"
		]

		Helpers::DeleteContent.destroy_document_with_links(ids)
  end
end
