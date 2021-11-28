# frozen_string_literal: true

require_relative '../command'

module Tmt
  module Commands
    class Config < Tmt::Command
      def initialize(options)
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        # Command logic goes here ...
        output.puts "OK"
      end
    end
  end
end
