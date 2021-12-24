# frozen_string_literal: true

module Rails
  module Surrender
    class Railtie < ::Rails::Railtie
      config.after_initialize do
        ActionController::Base.class_eval do
          include Rails::Surrender::ControllerAdditions
        end

        ActionController::API.class_eval do
          include Rails::Surrender::ControllerAdditions
        end

        ActiveRecord::Base.class_eval do
          include Rails::Surrender::ModelAdditions
          include Rails::Surrender::ModelFilterScopes
        end
      end
    end
  end
end
