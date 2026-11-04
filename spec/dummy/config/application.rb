# frozen_string_literal: true

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'rails/surrender'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.api_only = true
    # Eager load like production does, so models are defined before the after_initialize hooks run.
    config.eager_load = true
    config.logger = Logger.new(nil)
    config.secret_key_base = 'dummy'
    config.hosts.clear
    config.action_dispatch.show_exceptions = :none
  end
end
