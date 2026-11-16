# frozen_string_literal: true

module Rails
  module Surrender
    # Hooks surrender into Rails as each framework loads. Using load hooks rather than after_initialize matters
    # in eager loaded environments, where models call `surrenders` before after_initialize runs.
    class Railtie < ::Rails::Railtie
      config.surrender = ActiveSupport::OrderedOptions.new
      config.surrender.default_per_page = 50
      config.surrender.max_per_page = 100
      config.surrender.menus = false
      config.surrender.menu_param = 'menu'

      # Built once at boot, so a page size setting that makes no sense stops the app from starting.
      initializer 'rails_surrender.page_size' do |app|
        Rails::Surrender.page_size = Rails::Surrender::Selection::PageSize.new(
          default: app.config.surrender.default_per_page, max: app.config.surrender.max_per_page
        )
      end

      initializer 'rails_surrender.menu_param' do |app|
        Rails::Surrender.menu_param = Rails::Surrender::MenuParam.new(
          enabled: app.config.surrender.menus, name: app.config.surrender.menu_param
        )
      end

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
