module V2
  class LookupsController < ApplicationController
    def lookup_by_base_paths
      if base_paths.length > 100
        raise CommandError.new(code: 400, message: "base_paths must contain less than 100 items")
      end

      render json: Queries::LookupByBasePaths.call(base_paths)
    end

  private

    def base_paths
      params.fetch(:base_paths)
    end
  end
end
