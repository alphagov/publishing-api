# Generated from live Router API (routes which have a redirect, but handler is backend so redirect isn't actioned):
# routes = Route.where(backend_id: "government-frontend", handler: "backend").where(incoming_path: /^\/hmrc.*/).nin(redirect_to: nil).pluck(:incoming_path, redirect_to)
# routes.map { |x| { base_path: x[0], redirect_to: x[1] }}
routes = [
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg64575", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg66541", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76740", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76747", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76748", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76907", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76910", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76921", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76922", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76926", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg76928", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77002", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77003", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77004", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77006", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77017", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77018", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/capital-gains-manual/cg77019", redirect_to: "/hmrc-internal-manuals/capital-gains-manual" },
  { base_path: "/hmrc-internal-manuals/compliance-operational-guidance/cog940475", redirect_to: "/hmrc-internal-manuals/compliance-operational-guidance/cog900000" },
  { base_path: "/hmrc-internal-manuals/employment-income-manual/eim42776", redirect_to: "/hmrc-internal-manuals/employment-income-manual" },
  { base_path: "/hmrc-internal-manuals/international-manual/intm269078", redirect_to: "/hmrc-internal-manuals/international-manual" },
  { base_path: "/hmrc-internal-manuals/international-manual/intm269079", redirect_to: "/hmrc-internal-manuals/international-manual" },
  { base_path: "/hmrc-internal-manuals/international-manual/intm422150", redirect_to: "/hmrc-internal-manuals/international-manual" },
  { base_path: "/hmrc-internal-manuals/landfill-tax-liability/lft1000", redirect_to: "/hmrc-internal-manuals/landfill-tax-liability" },
  { base_path: "/hmrc-internal-manuals/landfill-tax-liability/lft1030", redirect_to: "/hmrc-internal-manuals/landfill-tax-liability" },
  { base_path: "/hmrc-internal-manuals/landfill-tax-liability/lft13000", redirect_to: "/hmrc-internal-manuals/landfill-tax-liability" },
  { base_path: "/hmrc-internal-manuals/landfill-tax-liability/lft13080", redirect_to: "/hmrc-internal-manuals/landfill-tax-liability" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052200", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052300", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052400", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052500", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052600", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm052700", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/pensions-tax-manual/ptm054200", redirect_to: "/hmrc-internal-manuals/pensions-tax-manual" },
  { base_path: "/hmrc-internal-manuals/shares-and-assets-valuation-manual/svm116000", redirect_to: "/hmrc-internal-manuals/shares-and-assets-valuation-manual" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8000", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8010", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8020", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8030", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8100", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8110", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8120", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8121", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8122", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8123", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8130", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8140", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8150", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8151", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8152", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8153", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8154", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8155", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8156", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8157", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8158", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8160", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8161", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8162", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8163", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8164", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8166", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8167", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8170", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8200", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
  { base_path: "/hmrc-internal-manuals/venture-capital-schemes-manual/8300", redirect_to: "/hmrc-internal-manuals/venture-capital-schemes-manual/vcm8300" },
]

desc "Unpublishes and redirect HMRC manuals that were republished, incorrectly due to incorrect state in Publishing API"
task tmp_unpublish_and_redirect_hmrc_manuals: :environment do
  grouped_sections = routes.group_by do |route|
    route[:base_path].split("/")[0..2].join("/")
  end

  manual_base_paths = grouped_sections.keys

  live_parent_manuals = Edition.where(base_path: manual_base_paths, state: "published")

  unless live_parent_manuals.count == manual_base_paths.count
    return "#{manual_base_paths - live_parent_manuals.pluck(:base_path)} parent manuals are not live"
  end

  detached_live_section_routes = live_parent_manuals.flat_map do |manual_edition|
    child_section_groups = manual_edition.details[:child_section_groups]

    live_attached_section_base_paths = if child_section_groups.present?
                                         manual_edition.details[:child_section_groups]
                                                       .last[:child_sections]
                                                       .pluck(:base_path).sort
                                       else
                                         []
                                       end

    live_section_routes = grouped_sections[manual_edition.base_path]

    live_section_routes.reject do |route|
      live_attached_section_base_paths.include?(route[:base_path])
    end
  end

  base_paths = routes.map { |route| route[:base_path] }
  live_sections = Edition.where(base_path: base_paths, state: "published")

  unless live_sections.count == routes.count
    return "#{base_paths - live_sections.pluck(:base_path)} sections are not live"
  end

  live_sections.map do |section|
    detached_section = detached_live_section_routes.find { |route| route[:base_path] == section.base_path }

    put_payload = {
      content_id: section.content_id,
      document_type: "redirect",
      schema_name: "redirect",
      publishing_app: "hmrc-manuals-api",
      base_path: detached_section[:base_path],
      redirects: [
        {
          path: detached_section[:base_path],
          type: "exact",
          destination: detached_section[:redirect_to],
        },
      ],
      update_type: "major",
    }

    put_response = Commands::V2::PutContent.call(put_payload)
    puts put_response

    publish_response = Commands::V2::Publish.call({ content_id: section.content_id, update_type: "major" })
    puts publish_response
  end
end
