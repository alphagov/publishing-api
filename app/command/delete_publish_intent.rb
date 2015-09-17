class Command::DeletePublishIntent < Command::BaseCommand
  def call
    services.service(:live_content_store).delete_publish_intent(base_path)

    Command::Success.new({})
  end
end
