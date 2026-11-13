# frozen_string_literal: true

module Rails
  module Surrender
    module Params
      # A query param that lists names, names with values, and nested lists, such as `genre:fantasy, author:[name]`.
      # It is read as the YAML of a flow sequence, so values come back typed: `long:true` holds true, not 'true'.
      class ListParam
        # YAML needs a space after each comma and colon that separates entries, but not inside quoted values, where it
        # would change the value: '13:30' must stay '13:30'.
        SEPARATORS_OUTSIDE_QUOTES = /'[^']*'|"[^"]*"|[,:]/

        # `param` names the query param in the error a malformed value raises.
        def self.parse(text, param:)
          spaced = text.to_s.gsub(SEPARATORS_OUTSIDE_QUOTES) { |match| match.length == 1 ? "#{match} " : match }
          Psych.safe_load("[#{spaced}]")
        rescue Psych::Exception
          raise Error, I18n.t('surrender.error.query_string.incorrect_format', param: param)
        end
      end
    end
  end
end
