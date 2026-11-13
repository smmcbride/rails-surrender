# frozen_string_literal: true

# Counts the SQL queries a block runs, ignoring schema lookups and transaction bookkeeping.
module QueryCounter
  IGNORED = %w[SCHEMA TRANSACTION].freeze

  def count_queries(&)
    count = 0
    counter = lambda do |*, payload|
      count += 1 unless IGNORED.include?(payload[:name]) || payload[:sql].start_with?('SAVEPOINT', 'RELEASE')
    end
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end
end

RSpec.configure { |config| config.include QueryCounter }
