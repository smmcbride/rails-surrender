# frozen_string_literal: true

module Rails
  # Base namespace for the entire project
  module Surrender
  end
end

require 'kaminari'
require 'oj'

require 'rails/surrender/controller_additions'
require 'rails/surrender/exceptions'
require 'rails/surrender/model_additions'
require 'rails/surrender/model_filter_scopes'
require 'rails/surrender/railtie'
require 'rails/surrender/render/ids'
require 'rails/surrender/render/controller'
require 'rails/surrender/render/count'
require 'rails/surrender/render/resource'
require 'rails/surrender/render/resource/inclusion_mapper'
require 'rails/surrender/response'
require 'rails/surrender/version'

# Load Surrender specific error messages
locale_path = Dir.glob("#{__dir__}/surrender/config/locales/*.{rb,yml}")
I18n.load_path += locale_path unless I18n.load_path.include?(locale_path)

# ActiveRecord Patches required for proper functionality
require 'rails/surrender/config/initializers/active_record_associations_patch'
require 'rails/surrender/config/initializers/active_record_preloader_patch'
