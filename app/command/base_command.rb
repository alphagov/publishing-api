class Command::BaseCommand
  def self.call(payload)
    self.new(payload).call
  end

  def initialize(payload)
    @payload = payload
  end

private
  attr_reader :payload

  def base_path
    payload[:base_path]
  end
end
