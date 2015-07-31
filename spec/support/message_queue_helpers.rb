module MessageQueueHelpers

  # Messages don't necessarily appear on the queue immediately, and
  # queue.pop is non-blocking.  It will return [nil, nil, nil] if
  # there are no messages on the queue.
  #
  # retry a few times to help with reliably picking up a message.
  def wait_for_message_on(queue, tries = 3)
    tries.times do |n|
      delivery_info, properties, payload = queue.pop
      return delivery_info, properties, payload unless delivery_info.nil?
      sleep 0.1
    end
    fail "No message found on queue"
  end

end
