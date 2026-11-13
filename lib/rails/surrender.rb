# frozen_string_literal: true

module Rails
  # Base namespace for the entire project
  module Surrender
  end
end

require 'kaminari'
require 'oj'

require 'rails/surrender/default_ability'
require 'rails/surrender/controller_additions'
require 'rails/surrender/exceptions'
require 'rails/surrender/fields/field_tree'
require 'rails/surrender/model_additions'
require 'rails/surrender/railtie'
require 'rails/surrender/selection/filtering'
require 'rails/surrender/selection/selection'
require 'rails/surrender/selection/sorting'
require 'rails/surrender/render/resource'
require 'rails/surrender/response'
require 'rails/surrender/version'
