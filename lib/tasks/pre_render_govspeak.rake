class PreRenderGovspeak
  def render_govspeak_in_editions(from_edition_id, batch_size)
    update_edition_details(from_edition_id, batch_size) do |details|
      GovspeakDetailsRenderer.new(details).render
    end
  end

  def remove_govspeak_in_editions(from_edition_id, batch_size)
    update_edition_details(from_edition_id, batch_size) do |details|
      GovspeakDetailsRenderer.new(details).remove_content_rendered_by_publishing_api
    end
  end

private

  def update_edition_details(from_edition_id, batch_size, &block)
    editions = Edition.where.not(content_store: nil).order(:id).where(id: from_edition_id..)
    max_edition_id = editions.maximum(:id)

    puts "Processing from edition #{from_edition_id} to edition #{max_edition_id}"

    editions.find_in_batches(batch_size:).with_index do |batch, i|
      estimated_completion_pct = percentage_complete(batch.first.id, from_edition_id, max_edition_id)
      puts "Processing batch #{i} (from id #{batch.first.id}, estimated completion #{estimated_completion_pct})"

      editions_to_update = []
      batch.each do |edition|
        new_details = block.call(edition.details)
        if new_details != edition.details
          edition.details = new_details
          editions_to_update << edition
        end
      end

      if editions_to_update.any?
        ids = editions_to_update.map(&:id)
        puts "Updating #{editions_to_update.count} editions from #{ids.min} to #{ids.max}"
        Edition.transaction do
          editions_to_update.each do |edition|
            edition.save!
          rescue StandardError => e
            warn "Edition #{edition.id} failed to save: #{e.inspect}"
          end
        end
      end
    end

    puts "Vacuuming editions..."
    ActiveRecord::Base.connection.execute "VACUUM editions"

    puts "Done! 🎉"
  end

  def percentage_complete(current, first, final)
    completion = (current - first).to_f / (final - first)
    "#{(completion * 100).round(1)}%"
  end
end

namespace :pre_render_govspeak do
  pre_render_govspeak = PreRenderGovspeak.new

  desc "Renders any govspeak content in the details field of live / draft editions"
  task :render, %i[from_edition_id batch_size] => :environment do |_, args|
    from_edition_id = args.from_edition_id.to_i
    batch_size = args.batch_size&.to_i || 1000

    pre_render_govspeak.render_govspeak_in_editions(from_edition_id, batch_size)
  end

  desc "Removes any govspeak content rendered by publishing-api from the details field of live / draft editions"
  task :remove, %i[from_edition_id batch_size] => :environment do |_, args|
    from_edition_id = args.from_edition_id.to_i
    batch_size = args.batch_size&.to_i || 1000

    pre_render_govspeak.remove_govspeak_in_editions(from_edition_id, batch_size)
  end
end
