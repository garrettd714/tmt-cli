# frozen_string_literal: true

require_relative '../command'
require_relative '../db'

module Tmt
  module Commands
    # Dxfeed symbols for use with `tmt-refresh`
    class TastyDxfeed < Tmt::Command
      def initialize(options) # rubocop:disable Lint/MissingSuper
        @options = options
      end

      def execute(_input: $stdin, output: $stdout)
        output.puts Trade.active.map(&:symbols).flatten.compact.join(',')
      end
    end
  end
end
