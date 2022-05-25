# frozen_string_literal: true

require_relative '../command'
require_relative '../db'

module Tmt
  module Commands
    # Close a trade
    class Close < Tmt::Command
      attr_reader :id, :mark, :fees

      def initialize(id, mark, fees, options) # rubocop:disable Lint/MissingSuper
        @id = id
        @mark = mark # fill price
        @fees = fees
        @options = options
      end

      def execute(_input: $stdin, output: $stdout)
        return output.puts pastel.red('Trade already closed') if trade.closed?

        trade.close! if trade.update!(mark: mark, fees: fees)
        output.puts pastel.green('Trade closed')
      end

      private

      def trade
        @trade ||= id.to_i.zero? ? Trade.where('lower(ticker) = ?', id.downcase).last : Trade.find(id)
      end
    end
  end
end
