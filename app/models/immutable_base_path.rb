module ImmutableBasePath
  extend ActiveSupport::Concern

  included do
    validates_with BasePathValidator

    attr_accessor :mutable_base_path

    def mutable_base_path?
      mutable_base_path
    end
  end
end
