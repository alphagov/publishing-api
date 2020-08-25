# FIXME: Remove this task once it has been run in production
namespace :update_document_type do
  desc "Temporary task to update document type dfid_research_output to research_for_development_output"
  task dfid_research_output: :environment do
    dfid_research_outputs = Edition.where(
      publishing_app: "specialist-publisher", document_type: "dfid_research_output"
    )

    dfid_research_outputs.update_all(document_type: "research_for_development_output")

    puts "Changed #{dfid_research_outputs.count} document types to `research_for_development_output`"
    puts "Now representing downstream"
    Rake::Task["represent_downstream:document_type"].invoke('research_for_development_output')
  end
end

