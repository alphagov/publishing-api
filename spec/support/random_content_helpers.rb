require "govuk_schemas"

module RandomContentHelpers
  def generate_random_edition(base_path)
    random = GovukSchemas::RandomExample.for_schema(publisher_schema: "placeholder")
    payload = random.payload
    random.merge_and_validate(
      base_path: base_path,
      # TODO: don't allow placeholder redirect, it doesn't make sense
      document_type: payload["document_type"] == "redirect" ? "guide" : payload["document_type"],
      # TODO: random schemas should generate valid routes and redirects
      routes: [
        { "path" => base_path, "type" => "prefix" }
      ],
      redirects: [],
      title: "Something not empty", # TODO: make schemas validate title length
      rendering_app: "government-frontend", # TODO: remove after https://github.com/alphagov/govuk-content-schemas/pull/575
      publishing_app: "publisher", # TODO: remove after https://github.com/alphagov/govuk-content-schemas/pull/575
    )
  end

  def random_content_failure_message(response, edition)
    <<-DOC
    Failed #{response.request.method} #{response.request.fullpath}

    Content:
    #{JSON.pretty_generate(edition)}

    Response:
    #{JSON.pretty_generate(parsed_response)}"
    DOC
  end
end
