module V2
  class SchemasController < ApplicationController
    def index
      render json: SchemaService.all_schemas
    end

    def show
      render json: SchemaService.find_schema_by_name(params[:id])
    end
  end
end
