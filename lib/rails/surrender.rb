# frozen_string_literal: true

module Rails
  # Base namespace for the entire project
  module Surrender
    class << self
      # The page size the app configures with config.surrender.default_per_page and max_per_page, set at boot.
      attr_writer :page_size

      def page_size
        @page_size ||= Selection::PageSize.new
      end
    end
  end
end

require 'kaminari'
require 'oj'

require 'rails/surrender/default_ability'
require 'rails/surrender/controller_additions'
require 'rails/surrender/exceptions'
require 'rails/surrender/fields/field_tree'
require 'rails/surrender/menu/menu'
require 'rails/surrender/model_additions'
require 'rails/surrender/railtie'
require 'rails/surrender/selection/filtering'
require 'rails/surrender/selection/selection'
require 'rails/surrender/selection/sorting'
require 'rails/surrender/render/resource'
require 'rails/surrender/response'
require 'rails/surrender/version'
