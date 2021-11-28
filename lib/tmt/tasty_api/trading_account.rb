# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'json'

module Tmt
  module TastyApi
    # class comment
    class TradingAccount
      attr_reader :account_number, :external_id, :is_margin, :nickname

      def initialize(options)
        @account_number = options['account-number']
        @external_id = options['external-id']
        @is_margin = options['margin-or-cash'] == 'Margin'
        @nickname = options['nickname']
      end

      #### Get accounts
      # {"data"=>
      #   {"items"=>
      #     [{"account"=>
      #        {"account-number"=>"5WW84887",
      #         "external-id"=>"A1f645113-ccce-4803-8604-1d43e638e846",
      #         "opened-at"=>"2021-10-14T17:36:16.753+00:00",
      #         "nickname"=>"IV League",
      #         "account-type-name"=>"Individual",
      #         "day-trader-status"=>false,
      #         "is-closed"=>false,
      #         "is-firm-error"=>false,
      #         "is-firm-proprietary"=>false,
      #         "is-test-drive"=>false,
      #         "margin-or-cash"=>"Margin",
      #         "is-foreign"=>false,
      #         "funding-date"=>"2021-10-19",
      #         "investment-objective"=>"SPECULATION",
      #         "futures-account-purpose"=>"SPECULATING",
      #         "suitable-options-level"=>"No Restrictions",
      #         "created-at"=>"2021-10-14T17:36:16.758+00:00"},
      #       "authority-level"=>"owner"},
      #
      def self.get_accounts(session)
        uri = URI("#{session.url}/customers/me/accounts")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.to_s)
        request['Authorization'] = session.session_token
        response = http.request(request)
        raise StandardError, 'Error fetching "get_accounts" API' unless response.code.to_i == 200

        [].tap do |results|
          JSON.parse(response.body)['data']['items'].map { |i| i['account'] }.each do |acct|
            results << new(acct)
          end
        end
      end

      def get_balance(session)
        uri = URI("#{session.url}/accounts/#{account_number}/balances")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.to_s)
        request['Authorization'] = session.session_token
        response = http.request(request)
        raise StandardError, 'Error fetching "get_balance" API' unless response.code.to_i == 200

        JSON.parse(response.body)['data']
      end

      def get_positions(session)
        uri = URI("#{session.url}/accounts/#{account_number}/positions")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.to_s)
        request['Authorization'] = session.session_token
        response = http.request(request)
        raise StandardError, 'Error fetching "get_positions" API' unless response.code.to_i == 200

        JSON.parse(response.body)['data']['items']
      end
    end
  end
end
