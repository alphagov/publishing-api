class DownstreamPayload
  attr_reader :edition, :payload_version, :draft

  def initialize(edition, payload_version, draft: false)
    @edition = edition
    @payload_version = payload_version
    @draft = draft
  end

  delegate :state, to: :edition

  delegate :base_path, to: :edition

  delegate :unpublished?, to: :edition

  def content_store_action
    return :no_op unless base_path
    return :put unless unpublished?

    case unpublishing.type
    when "vanish" then :delete
    when "substitute" then :no_op
    else :put
    end
  end

  def content_store_payload
    content_store_presenter.for_content_store(payload_version)
  end

  def message_queue_payload
    message_queue_presenter.for_message_queue(payload_version)
  end

  delegate :expanded_links, to: :content_presenter

private

  def unpublishing
    edition.unpublishing
  end

  def content_presenter
    @content_presenter ||= Presenters::EditionPresenter.new(edition, draft:)
  end

  def redirect_presenter
    if unpublishing
      Presenters::RedirectPresenter.from_unpublished_edition(edition)
    else
      Presenters::RedirectPresenter.from_published_edition(edition)
    end
  end

  def gone_presenter
    Presenters::GonePresenter.from_edition(edition)
  end

  def vanish_presenter
    Presenters::VanishPresenter.from_edition(edition)
  end

  def substitute_presenter
    Presenters::SubstitutePresenter.from_edition(edition)
  end

  def content_store_presenter
    if unpublishing
      return redirect_presenter if unpublishing.type == "redirect"
      return gone_presenter if unpublishing.type == "gone"
    end

    return redirect_presenter if edition.document_type == "redirect"

    content_presenter
  end

  def message_queue_presenter
    return redirect_presenter if edition.document_type == "redirect"
    return content_presenter unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_presenter
    when "gone" then gone_presenter
    when "vanish" then vanish_presenter
    when "substitute" then substitute_presenter
    when "withdrawal" then content_presenter
    else
      logger.warn("Unexpected unpublishing type #{unpublishing.type}")
      content_presenter
    end
  end
end
