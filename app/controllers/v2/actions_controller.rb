module V2
  class ActionsController < ApplicationController
    def index
      TimedFeature.check!(owner: "Tijmen", expires: "2017-04-22")

      actions = Action
        .where(content_id: params[:content_id])
        .as_json(only: %i[action user_uid created_at])

      render json: actions
    end

    def create
      response = Commands::V2::PostAction.call(action_params)
      render status: response.code, json: response
    end

  private

    def action_params
      payload.merge(content_id: content_id)
    end

    def content_id
      params.fetch(:content_id)
    end
  end
end
