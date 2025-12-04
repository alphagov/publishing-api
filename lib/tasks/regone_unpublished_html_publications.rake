desc "Does a forced gone on HTML Publications that have been unpublished but still appear live in content store"
task regone_unpublished_html_publications: :environment do
  successes = 0
  documents = Document.where(content_id: UNPUBLISHED_IDS)
  found = documents.count

  documents.each do |unpublished_document|
    successes += 1 if regone_unpublished_document(unpublished_document)
  end

  Rails.logger.info("Of #{found} unpublished, #{successes} were regone'd")
end

UNPUBLISHED_IDS = %w[063e46e6-9e0f-4c1b-a53f-3ec587a63287
                     ac94af44-b002-4dbb-b9e4-2f696449cd6f
                     75018425-f0ca-4382-bc52-53faa2c0bd8f
                     f87a8ad1-b9eb-4491-8747-0f740323b0e8
                     c05af93a-1305-4509-ad84-cf7468c69f01
                     1987c4c9-fc05-4678-a96f-3e274a9e77a0
                     b6bf6ffa-856e-4be9-ac5e-3b6cc822cbac
                     cd41d922-4183-4568-a1b0-89695f662e1b
                     01342cfd-ecbc-473d-b748-9fe3e7aee899
                     a623aeba-a418-44b9-aadc-aa167bc2fde6
                     5f79af75-cab1-452a-a0e8-86a7e26d8190
                     fade1913-76a4-4ab3-84d0-7e7a48a31c2d
                     0b606fc6-4877-4b8f-8c6b-0ba9182738ac
                     fe55bea0-9c6c-4625-9248-ff1dccce2eae
                     ddedfe26-56e9-4788-9d99-605350956cea
                     6e4b4cbc-13cb-4886-8244-97c09a78d0d0
                     0e9b8cee-a4c6-4a97-b3e0-a6bf520932bf
                     83019bd5-497f-4a04-a7a1-b85eb6f3a01f
                     91052921-1984-4c42-891c-199d5dfd6b01
                     03be3e04-30bb-4110-9a77-c101420dabc4
                     8d8f6adf-f21b-43d9-9ee0-8b6d7b059be2
                     5d12be80-e395-4c8a-a70d-03e2e427e2ce
                     513801ce-d8a1-4a9e-a596-cffa09f431d9
                     7ed6b02e-26aa-4dab-b4b8-a44e464365cd
                     f1a663a9-0df7-4d99-aa26-04ae34619ff5
                     c1b68140-0f93-4e3d-ad0e-a18e547240be
                     5a0f45a3-4389-4bb5-86cc-7935a2fc3209
                     d0a90561-7273-4a1a-8cde-4dbf7e6e3567
                     2aad75d8-d123-4499-aba8-a067285db3cd
                     f01eab8d-87aa-4415-ad04-890933751832
                     1481b00e-22e6-4583-8be0-d2112c081ce8
                     2800fe77-3bec-46da-98ee-8815fe727099
                     0ce1cdd3-5850-4e8a-9e85-c30c3bdf8bec
                     d481898a-b09a-44ee-ae19-5bd16493a600
                     db886ffb-4eb9-4092-bd59-ed3261931cef
                     cb328c07-eefb-4a44-a091-ae71f18b726b
                     76ba20e5-c843-4f3f-bae9-a3273d7fa895
                     513801ce-d8a1-4a9e-a596-cffa09f431d9].freeze

def regone_unpublished_document(document)
  edition = document.live
  if edition.nil?
    puts("ERROR: No live edition for #{document.content_id}")
    return false
  end

  if edition.state != "unpublished"
    puts("ERROR: Live edition wasn't unpublished for #{document.content_id}")
    return false
  end

  if document.draft.present?
    Commands::V2::DiscardDraft.call(
      {
        content_id: document.content_id,
        locale: document.locale,
      },
    )
  end

  Commands::V2::Unpublish.call(
    {
      content_id: document.content_id,
      locale: document.locale,
      type: "gone",
    },
  )

  true
end
