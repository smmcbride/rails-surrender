module Rails
  module Surrender
    class Railtie < ::Rails::Railtie
      config.after_initialize do

        ActionController::Base.class_eval do
          include Rails::Surrender::ControllerAdditions
          puts 'here'
        end

        ActionController::API.class_eval do
          include Rails::Surrender::ControllerAdditions
          puts 'here'
        end

        ActiveRecord::Base.class_eval do
          include Rails::Surrender::ModelAdditions
          puts 'here'
        end
      end
    end
  end
end
