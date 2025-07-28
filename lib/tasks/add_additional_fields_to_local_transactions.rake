desc "Create editions of two existing local_transaction documents with specific fields added"
task add_additional_fields_to_local_transactions: :environment do
  additional_fields = {
    cta_text: "Find a registered childminder in your area",
    before_results: [
      {
        content: "<h2>Find a registered childminder through your local council</h2>",
        content_type: "text/govspeak",
      },
    ],
    after_results: [
      {
        content: "<h2 id=\"find-a-childminder-through-a-registered-childminding-agency\">Find a childminder through a registered childminding agency</h2>
                  <p>You can also search for a childminder using the following childminding agencies:</p>

                  <ul>
                    <li>
                      <p><a rel=\"external\" href=\"https://scachildcare.co.uk/our-childminders/\">Suffolk Childcare Agency</a> (national)</p>
                    </li>
                    <li>
                      <p><a rel=\"external\" href=\"https://www.tiney.co/childminders/\">Tiney</a> (national)</p>
                    </li>
                    <li>
                      <p><a rel=\"external\" href=\"https://www.athomechildcare.co.uk/looking-for-childcare\">@Home Childcare</a> (regional)</p>
                    </li>
                    <li>
                      <p><a rel=\"external\" href=\"https://usearlyyears.co.uk/\">Unique Support Early Years Agency</a> (regional)</p>
                    </li>
                  </ul>",
        content_type: "text/govspeak",
      },
    ],
  }

  doc = Document.where(content_id: "2f2ee25a-30c8-4ded-a160-88783f978206").first
  edition = doc.live
  payload = {
    base_path: edition.base_path,
    content_id: edition.content_id,
    description: edition.description,
    details: edition.details.merge(additional_fields),
    document_type: edition.document_type,
    publishing_app: edition.publishing_app,
    rendering_app: edition.rendering_app,
    routes: edition.routes,
    update_type: "minor",
  }

  response = Commands::V2::PutContent.call(payload)

  puts("Response: [#{response}]")
end
