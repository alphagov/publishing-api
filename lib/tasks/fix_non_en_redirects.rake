namespace :fix_non_en_redirects do
  desc "Fix non-en redirects for content, filtering by content_id."
  namespace :by_content_id do
    def fix_draft_redirect(draft_redirect_edition, correct_locale, dry_run:)
      if dry_run
        puts "Would change Document #{draft_redirect_edition.document.id} from locale: #{draft_redirect_edition.document.locale} to locale: #{correct_locale}"

      else
        # This is really bad, as it's not going through the API of
        # the Publishing API, but unfortunately I don't see a
        # neater way of fixing this issue with the Document having
        # the wrong locale.
        draft_redirect_edition
          .document
          .update!(
            locale: correct_locale,
          )

        publish_payload = {
          content_id: draft_redirect_edition.document.content_id,
          locale: correct_locale,
          update_type: "major", # Some redirects may be missing an
                                # update_type, so work around that by
                                # specifying one here
        }

        Commands::V2::Publish.call(publish_payload)
      end
    end

    def fix_for_content_id(content_id, dry_run:)
      document_ids = Document.where(content_id: content_id).pluck(:id)

      relevant_base_paths = Edition.where(
        document_id: document_ids,
      ).where.not(
        document_type: "redirect",
      ).select(:base_path)

      draft_redirect_editions = Edition.where(
        document_type: "redirect",
        state: "draft",
        base_path: relevant_base_paths,
      ).order(:id)

      draft_redirect_editions.each do |draft_redirect_edition|
        editions_matching_destination = Edition.where(
          base_path: draft_redirect_edition.redirects.first[:destination],
        ).count

        # Don't change redirects that don't redirect to a base_path
        # for which no edition exists, as this probably means the
        # target edition has been discarded
        next if editions_matching_destination.zero?

        correct_locale_possibilities = Edition.joins(
          :document,
        ).where(
          base_path: draft_redirect_edition.base_path,
        ).where.not(
          document_type: "redirect",
          "documents.locale" => "en",
        ).pluck(
          "documents.locale",
        ).uniq

        if correct_locale_possibilities.length == 1
          correct_locale = correct_locale_possibilities[0]

          fix_draft_redirect(draft_redirect_edition, correct_locale, dry_run: dry_run)
        else
          raise "locale for #{draft_redirect_edition.base_path} is unclear: #{correct_locale_possibilities}"
        end
      end
    end

    task :dry, %i[content_id] => :environment do |_, args|
      fix_for_content_id(args[:content_id], dry_run: true)
    end

    task :real, %i[content_id] => :environment do |_, args|
      fix_for_content_id(args[:content_id], dry_run: false)
    end
  end
end
