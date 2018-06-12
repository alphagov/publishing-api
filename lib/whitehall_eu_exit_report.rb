require "fileutils"

class WhitehallEuExitReport
  def self.call(*args)
    new(*args).call
  end

  def initialize(path:)
    @path = path
  end

  def call
    FileUtils::mkdir_p(path)
  end

  private_class_method :new

private

  attr_reader :path
end
