# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from Rails::Surrender::Error do |error|
    render status: :bad_request, json: { error: error.message }
  end
end
