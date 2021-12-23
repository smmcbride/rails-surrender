module Rails
  module Surrender
    module YamlQueryParser
      def self.parse(query_string)
        query_string ||= '' # empty string in case nil is passed
        Psych.safe_load('[' + query_string.gsub(/(,|:)/, '\1 ') + ']')
      rescue
        raise Error, I18n.t('surrender.error.query_string.incorrect_format', params: { a: query_string })
      end
    end
  end
end
