# TODO: After running this task, it can be deleted
namespace :taxonomy do
  desc 'Change ownership of taxons from collections-publisher to content-tagger'
  task change_ownership: :environment do
    ContentItem.transaction do
      taxons = ContentItem.where(document_type: 'taxon')
      puts "Found #{taxons.count} taxons"
      taxons.each do |taxon|
        puts "Changing #{taxon.title} from #{taxon.publishing_app} to content-tagger"
        taxon.update!(publishing_app: 'content-tagger')
      end
    end
  end
end
