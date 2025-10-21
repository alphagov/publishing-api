desc "Replace beta phase on HMRC manuals and manual sections with live"
task hmrc_manuals_go_live: :environment do
  schema_name = %w[hmrc_manual hmrc_manual_section]
  items = Edition.live.where(schema_name:, phase: "beta")

  puts("Updating HMRC Manual records from beta to live")
  items.update_all(phase: "live")
  puts("Complete!")
end
