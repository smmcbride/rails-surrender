module Rails
  module Surrender
  end
end

require 'kaminari'
require 'oj'

require 'rails/surrender/controller_additions'
require 'rails/surrender/exceptions'
require 'rails/surrender/model_additions'
require 'rails/surrender/railtie'
require 'rails/surrender/render'
require 'rails/surrender/response'
require 'rails/surrender/version'

# Load Surrender specific error messages
locale_path = Dir.glob(File.dirname(__FILE__) + "/rails/surrender/config/locales/*.{rb,yml}")
I18n.load_path += locale_path unless I18n.load_path.include?(locale_path)

# ActiveRecord Patches required for proper functionality
require 'rails/surrender/config/initializers/active_record_associations_patch'
require 'rails/surrender/config/initializers/active_record_preloader_patch'
