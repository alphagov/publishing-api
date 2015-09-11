class Command::DeletePublishIntent < Command::BaseCommand
  def call
    live_content_store.delete_publish_intent(base_path)
  end
end
