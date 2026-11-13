# frozen_string_literal: true

module Rails
  module Surrender
    # Hooks surrender into Rails as each framework loads. Using load hooks rather than after_initialize matters
    # in eager loaded environments, where models call `surrenders` before after_initialize runs.
    class Railtie < ::Rails::Railtie
      initializer 'rails_surrender.locales' do |app|
        app.config.i18n.load_path += Dir[File.expand_path('config/locales/*.yml', __dir__)]
      end

      initializer 'rails_surrender.action_controller' do
        ActiveSupport.on_load(:action_controller) { include Rails::Surrender::ControllerAdditions }
      end

      initializer 'rails_surrender.active_record' do
        ActiveSupport.on_load(:active_record) do
          include Rails::Surrender::ModelAdditions
          include Rails::Surrender::Selection::Filtering
          include Rails::Surrender::Selection::Sorting
        end
      end
    end
  end
end
