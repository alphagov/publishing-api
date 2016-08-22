module DataHygiene
  module DuplicateContentItem
    class DuplicateVersionForLocaleError < StandardError; end
    class DuplicateStateForLocaleError < StandardError; end
    class DuplicateBasePathForStateError < StandardError; end
  end
end
