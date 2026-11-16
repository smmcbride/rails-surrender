# frozen_string_literal: true

module Rails
  module Surrender
    # Serves the app menu. It inherits nothing from the app's controllers, so the app's authentication doesn't apply.
    class MenusController < ActionController::API
      # Its name would otherwise lead the app menu to a model named Menu.
      surrender_options :show, menu: false

      def show
        render(json: Response.new(data: AppMenu.new(Rails.application.routes.routes).as_json).json_data)
      end
    end
  end
end
