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
    @content_presenter ||= Presenters::EditionPresenter.new(edition, draft: draft)
  end

  def redirect_presenter
    RedirectPresenter.from_edition(edition)
  end

  def gone_presenter
    GonePresenter.from_edition(edition)
  end

  def vanish_presenter
    VanishPresenter.from_edition(edition)
  end

  def content_store_presenter
    return content_presenter unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_presenter
    when "gone" then gone_presenter
    else content_presenter
    end
  end

  def message_queue_presenter
    return content_presenter unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_presenter
    when "gone" then gone_presenter
    when "vanish" then vanish_presenter
    else content_presenter
    end
  end
end
