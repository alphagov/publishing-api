class DownstreamPayload
  attr_reader :edition, :payload_version, :draft

  def initialize(edition, payload_version, draft: false)
    @edition = edition
    @payload_version = payload_version
    @draft = draft
  end

  def state
    edition.state
  end

  def base_path
    edition.base_path
  end

  def unpublished?
    edition.unpublished?
  end

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
    return content_payload_for_content_store unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_payload_for_content_store
    when "gone" then gone_payload_for_content_store
    else content_payload_for_content_store
    end
  end

  def message_queue_payload
    return content_payload_for_message_queue unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_payload_for_message_queue
    when "gone" then gone_payload_for_message_queue
    when "vanish" then vanish_payload_for_message_queue
    else content_payload_for_message_queue
    end
  end

private

  def unpublishing
    edition.unpublishing
  end

  def content_presenter
    Presenters::EditionPresenter.new(edition, draft: draft)
  end

  def content_payload_for_content_store
    content_presenter.for_content_store(payload_version)
  end

  def content_payload_for_message_queue
    content_presenter.for_message_queue
  end

  def redirect_presenter
    RedirectPresenter.from_edition(edition)
  end

  def redirect_payload_for_content_store
    redirect_presenter.for_content_store(payload_version)
  end

  def redirect_payload_for_message_queue
    redirect_presenter.for_message_queue
  end

  def gone_presenter
    GonePresenter.from_edition(edition)
  end

  def gone_payload_for_content_store
    gone_presenter.for_content_store(payload_version)
  end

  def gone_payload_for_message_queue
    gone_presenter.for_message_queue
  end

  def vanish_presenter
    VanishPresenter.from_edition(edition)
  end

  def vanish_payload_for_message_queue
    vanish_presenter.for_message_queue
  end
end
