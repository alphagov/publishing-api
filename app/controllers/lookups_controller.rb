class LookupsController < ApplicationController
  def by_base_path
    base_paths = params.fetch(:base_paths)

    base_paths_and_content_ids = Edition.with_document.includes(:unpublishing)
      .where( base_path: base_paths)

    published = {}
    redirects = {}

    base_paths_and_content_ids.each do |edition|
      if redirected?(edition)
        redirects[edition.base_path] = edition.unpublishing.alternative_path
      elsif visible_on_live?(edition)
        published[edition.base_path] = edition.document.content_id
      end
    end

    if params[:include].present?
      response = {"published" => published, "redirected" => redirects}
      included = response.select do |key|
        params[:include].include?(key)
      end

      render json: included
    else
      render json: published
    end
  end

private

  def visible_on_live?(edition)
    unpublishing = edition.unpublishing
    edition.state == "published" || (unpublishing.present? && unpublishing.type == "withdrawal")
  end

  def redirected?(edition)
    unpublishing = edition.unpublishing
    unpublishing.present? && unpublishing.type == "redirect"
  end
end
