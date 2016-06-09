module Candidates
  class Linkables < BaseCandidate
    def perform(document_type, experiment)
      experiment_candidate(experiment) do
        Queries::GetLinkables.new(
          document_type: document_type,
        ).call
      end
    end
  end
end
