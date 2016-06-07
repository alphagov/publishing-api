class DebugController < ApplicationController
  skip_before_action :require_signin_permission!

  def show
    @presenter = Presenters::DebugPresenter.new(params[:content_id])
  end
end
