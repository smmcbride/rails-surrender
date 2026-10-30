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
require 'rails/surrender/model_additions'
require 'rails/surrender/model_filter_scopes'
require 'rails/surrender/railtie'
require 'rails/surrender/render/ids'
require 'rails/surrender/render/configuration'
require 'rails/surrender/render/count'
require 'rails/surrender/render/resource'
require 'rails/surrender/response'
require 'rails/surrender/version'
