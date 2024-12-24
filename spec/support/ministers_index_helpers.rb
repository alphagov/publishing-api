module MinistersIndexHelpers
  def create_organisation(title)
    create(
      :live_edition,
      title:,
      document_type: "organisation",
      schema_name: "organisation",
      base_path: "/government/organisations/#{title.parameterize}",
    )
  end

  def create_role(title, role_payment_type: nil, whip_organisation: nil)
    create(
      :live_edition,
      title: title,
      document_type: "ministerial_role",
      base_path: "/government/ministers/#{title.parameterize}",
      details: {
        attends_cabinet_type: nil,
        body: [{
          content: "# #{title}\nThe #{title} is the #{title} of His Majesty's Government",
          content_type: "text/govspeak",
        }],
        supports_historical_accounts: true,
        role_payment_type:,
        seniority: 100,
        whip_organisation:,
      },
    )
  end

  def appoint_person_to_role(person, role)
    role_appointment = create(
      :live_edition,
      title: "#{person.title} - #{role.title}",
      document_type: "role_appointment",
      schema_name: "role_appointment",
      details: {
        current: true,
        started_on: Time.zone.local(2024, 7, 5),
      },
    )

    create(
      :link_set,
      content_id: role_appointment.content_id,
      links_hash: { person: [person.content_id], role: [role.content_id] },
    )
  end

  def create_person(title)
    create(
      :live_edition,
      title: title,
      document_type: "person",
      schema_name: "person",
      base_path: "/government/people/#{title.parameterize}",
      details: {
        body: [{
          content: "#{title} A Role on 5 July 2024.",
          content_type: "text/govspeak",
        }],
        image: {
          url: "http://assets.dev.gov.uk/media/#{title.parameterize}.jpg",
          alt_text: title,
        },
      },
    )
  end

  def create_person_with_role_appointment(person_title, role_title)
    person = create_person(person_title)
    role = create_role(role_title)
    appoint_person_to_role(person, role)

    person
  end

  def add_link(target_content, link_type:, link_set:, position: 0)
    create(
      :link,
      position:,
      link_type:,
      link_set:,
      target_content_id: target_content.content_id,
    )
  end

  def add_department_link(department, target_content, link_type:)
    link_set = LinkSet.find_or_create_by!(content_id: department.content_id)

    create(
      :link,
      link_type:,
      link_set:,
      target_content_id: target_content.content_id,
    )
  end
end
