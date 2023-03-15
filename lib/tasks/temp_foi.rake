desc "Temporary rake task to extract data for a FOI request"
task temp_foi: :environment do
  role_appointments = Edition
    .where("published_at >= ?", "2022-01-01")
    .where(schema_name: "role_appointment", content_store: "live")
    .order(:published_at)

  ministerial_role_appointments = role_appointments.select do |role_appointment|
    all_links = Queries::LinksForEditionIds.new(role_appointment.id).merged_links
    role_link_content_id = all_links.dig(role_appointment.id, "role", 0)
    role_edition = Document.find_by(content_id: role_link_content_id).editions.last
    role_edition.document_type == "ministerial_role"
  end

  final = ministerial_role_appointments.map do |role_appointment|
    {
      name: role_appointment.title,
      started_on: role_appointment.details[:started_on],
      ended_on: role_appointment.details[:ended_on],
      current: role_appointment.details[:current],
      published_at: role_appointment.published_at,
    }
  end

  puts %w[name published_at started_on ended_on current].join(",")

  final.each do |line|
    puts ["\"#{line[:name]}\"", line[:published_at], line[:started_on], line[:ended_on], line[:current]].join(",")
  end
end
