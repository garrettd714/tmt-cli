# frozen_string_literal: true

require_relative '../command'
require_relative '../db'
require 'pastel'

module Tmt
  module Commands
    class Update < Tmt::Command
      attr_reader :id, :options

      def initialize(id, options) # rubocop:disable Lint/MissingSuper
        @id = id
        @options = options.merge(trade: trade)
      end

      def execute(_input: $stdin, output: $stdout)
        %i[mark ticker_price note].each do |attr|
          if options[attr]
            if attr == :note
              trade.assign_attributes(attr => "#{trade.note}#{options[attr]} [#{Time.now.strftime('%Y-%m-%d %H:%M')}]\n")
            else
              trade.assign_attributes(attr => options[attr])
            end
          end
        end

        if trade.save!
          output.puts pastel.green('Trade updated successfully')
        else
          output.puts pastel.red('Not implemented')
        end
      rescue TTY::Reader::InputInterrupt
        puts pastel.red('Cancelled input. Data not saved')
      end

      private

      def trade
        @trade ||= id.to_i.zero? ? Trade.where('lower(ticker) = ?', id.downcase).last : Trade.find(id)
      end
    end
  end
end
