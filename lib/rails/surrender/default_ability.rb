# frozen_string_literal: true

module Rails
  module Surrender
    # If cancancan is not installed, this class will be instantiated to allow all models to render.
    class DefaultAbility
      def can?(*)
        true
      end
    end
  end
end
