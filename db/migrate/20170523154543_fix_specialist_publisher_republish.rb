class FixSpecialistPublisherRepublish < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  # This migration is to fix the results of running a republish in Specialist
  # Publisher which, due to update_type oddities, ends up setting a bunch of
  # key dates to nil
  def up
    scope.find_each do |edition|
      unless edition.last_edited_at
        edition.last_edited_at = maximum_last_edited_at(edition.document_id)
      end

      unless edition.public_updated_at
        edition.public_updated_at = maximum_public_updated_at(edition.document_id)
      end

      next unless edition.changed?

      edition.save
    end
  end

private

  def scope
    e = Edition.arel_table
    d = Document.arel_table

    Edition
      .with_document
      .includes(:document)
      .where(publishing_app: "specialist-publisher")
      .where.not(content_store: nil)
      .where("last_edited_at IS NULL OR public_updated_at IS NULL")
      .where(
        e[:document_type].eq("cma_case").or(
          d[:content_id].in(content_ids)
        )
      )
  end

  def maximum_last_edited_at(document_id)
    Edition.where(document_id: document_id).maximum(:last_edited_at)
  end

  def maximum_public_updated_at(document_id)
    Edition.where(document_id: document_id).maximum(:public_updated_at)
  end

  # These content ids were run as rake tasks in:
  # https://deploy.publishing.service.gov.uk/job/run-rake-task/1155/console
  # https://deploy.publishing.service.gov.uk/job/run-rake-task/1156/console
  #
  # Errors in syntax of the job meant very few of the ids listed in the jobs
  # above actually ran.
  def content_ids
    %w(
      46fb4dec-d076-473a-8c42-f24d03e04b30
      d98d7b87-309e-47b9-9467-4ca2ac9ffbe5
    )
  end
end
