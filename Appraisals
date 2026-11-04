# frozen_string_literal: true

appraise 'rails-8.0' do
  gem 'rails', '~> 8.0.0'
  # ActiveSupport 8.0 passes quirks_mode to JSON.generate, which json 3 no longer accepts.
  gem 'json', '< 3'
end

appraise 'rails-8.1' do
  gem 'rails', '~> 8.1.0'
end
