# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'
ENV['DATABASE_URL'] = 'sqlite3::memory:'

require_relative 'application'

Rails.application.initialize!

require_relative 'schema'
require_relative 'routes'
