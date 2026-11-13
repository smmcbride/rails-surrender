# frozen_string_literal: true

# Records the SQL queries a block runs, ignoring schema lookups and transaction bookkeeping.
module QueryCounter
  IGNORED = %w[SCHEMA TRANSACTION].freeze

  def count_queries(&)
    capture_queries(&).size
  end

  def capture_queries(&)
    queries = []
    recorder = lambda do |*, payload|
      next if IGNORED.include?(payload[:name]) || payload[:sql].start_with?('SAVEPOINT', 'RELEASE')

      queries << payload[:sql]
    end
    ActiveSupport::Notifications.subscribed(recorder, 'sql.active_record', &)
    queries
  end
end

RSpec.configure { |config| config.include QueryCounter }
