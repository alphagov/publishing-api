class DebugController < ApplicationController
  def show
    @presenter = Presenters::DebugPresenter.new(params[:content_id])
  end
end
