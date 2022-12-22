class FixOrganisationRedirects < ActiveRecord::Migration[7.0]
  def up
    false_redirects = Edition
      .where(
        document_type: "redirect",
        schema_name: "redirect",
      )
      .where("created_at > :date", date: "2022-12-21 10:45")
      .where("base_path LIKE ?", "/government/organisations/%")

    Rails.logger.debug "deleting redirects: #{false_redirects.pluck(:base_path).join}"

    false_redirects.destroy_all

    published_organisations = Edition
      .where(
        document_type: "organisation",
        schema_name: "organisation",
        state: "published",
      )
      .where("created_at > :date", date: "2022-12-21 10:45")
      .where("base_path LIKE ?", "/government/organisations/%")

    published_organisations.each do |organisation|
      locale = organisation.document.locale

      next if locale == "en"

      next if organisation.base_path.ends_with?(".#{locale}")

      base_path = organisation.base_path

      correct_base_path = "#{base_path}.#{locale}"

      correct_routes = [{ "path" => correct_base_path, "type" => "exact" },
                        { "path" => "#{correct_base_path}.atom", "type" => "exact" }]

      Rails.logger.debug "updating route #{base_path} to #{correct_base_path}"

      organisation.update!(base_path: correct_base_path, routes: correct_routes)
    end

    unpublished_organisations = Edition
      .where(
        document_type: "organisation",
        schema_name: "organisation",
        state: "unpublished",
      )
      .where("created_at > :date", date: "2022-12-21 10:45")
      .where("base_path LIKE ?", "/government/organisations/%")

    unpublished_organisations.each do |organisation|
      locale = organisation.document.locale

      base_path = organisation.base_path

      if locale != "en" && !base_path.ends_with?(".#{locale}")
        correct_base_path = "#{base_path}.#{locale}"
        correct_routes = [{ "path" => correct_base_path, "type" => "exact" }, { "path" => "#{correct_base_path}.atom", "type" => "exact" }]

        Rails.logger.debug "updating route #{base_path} to #{correct_base_path}"

        organisation.update!(base_path: correct_base_path, routes: correct_routes)
      end

      organisation.update!(state: "published")
    end
  end
end
