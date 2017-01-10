module FindOrCreateLocked
  extend ActiveSupport::Concern

  class_methods do
    def find_or_create_locked(params)
      begin
        retries ||= 0
        self.transaction(requires_new: true) do
          entity = self.lock.find_by(params)
          entity || self.create!(params).lock!
        end
      rescue ActiveRecord::RecordNotUnique
        # This should never need more than 1 retry as the scenario this error
        # would occur is: inbetween rails find_by and create SELECT & INSERT
        # queries a concurrent request ran an INSERT. Thus on retry the
        # SELECT would succeed.
        # So if this actually throws an exception here we probably have a
        # weird underlying problem.
        retry if (retries += 1) == 1
      end
    end
  end
end
