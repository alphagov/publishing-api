class OneOffRedirectFixService
  def self.fix_redirects!
    editions = Edition.where(document_type: "redirect").joins(:document).where.not("documents.locale = 'en'")
    editions_updated = 0
    editions.each do |edition|
      updated = update_redirects(edition)
      if updated
        Commands::V2::RepresentDownstream.new.call([edition.content_id], queue: DownstreamQueue::LOW_QUEUE)
        editions_updated += 1
      end
    end
    Rails.logger.info "#{editions_updated} editions have been updated."
  end

  def self.update_redirects(edition)
    return false if edition.redirects.blank?

    if edition.redirects.count > 1
      Rails.logger.info "[RedirectsValueInvalid] edition #{edition.id} has more than one redirect."
      return false
    end

    next_base_path = edition.redirects.first[:destination]

    while (next_edition = Edition.where(base_path: next_base_path).order(:updated_at).last)
      break unless next_edition && next_edition.redirects.present?

      if next_base_path == edition.base_path
        Rails.logger.info "[RedirectDepthFix] edition #{edition.id} and #{next_edition.id} has a circular redirect"
        return false
      end

      if next_edition.redirects.count > 1
        Rails.logger.info "[RedirectsValueInvalid] edition #{next_edition.id} has more than one redirect. Unable to process earlier edition #{edition.id}"
        return false
      end

      next_base_path = next_edition.redirects.first[:destination]
    end

    redirect = edition.redirects.first
    redirect[:destination] = next_base_path
    edition.redirects = [redirect]
    begin
      edition.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.info "[RedirectDepthFix] #{edition.id} could not be updated: #{e.message}"
      return false
    end

    true
  end
end
