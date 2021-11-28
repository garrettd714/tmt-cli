# frozen_string_literal: true

module Tmt
  module TastyApi
    # class comment
    class OptionChain
      attr_reader :expiration

      def initialize(options)
        @expiration = options[:expiration].present? ? Date.parse(options[:expiration]) : nil
      end

      def get_option_chain(session, ticker)
        data = get_option_chain_data(session, ticker)

        results = []
        data['expirations'].each do |exp_data|
          exp_date = Date.parse(exp_data['expiration-date'])

          next if expiration.present? && expiration != exp_date

          results << exp_data.except('strikes')
        end
        results
      end

      private

      def get_futures_option_chain_data(_session, _ticker); end
      # uri = URI("#{session.url}/futures-option-chains/#{ticker}/nested") # ticker/no slash
      # data:
      #   futures:
      #   option-chains:[ # only one in array
      #     expirations: [
      #       asset: "ES"
      #       days-to-expiration: 23
      #       display-factor: "0.01"
      #       expiration-date: "2021-12-17"
      #       expires-at: "2021-12-17T14:30:00.000+00:00"
      #       notional-value: "0.5"
      #       option-contract-symbol: "ESZ1"
      #       option-root-symbol: "ES"
      #       root-symbol: "/ES"
      #       stops-trading-at: "2021-12-17T14:30:00.000+00:00"
      #       strike-factor: "1.0"
      #       strikes: [
      #         call: "./ESZ1 ESZ1  211217C4605"
      #         put: "./ESZ1 ESZ1  211217P4605"
      #         strike-price: "4605.0"
      #       ]
      #       tick-sizes: []
      #       underlying-symbol: "/ESZ1"
      #     ]
      #   ]


      def get_option_chain_data(session, ticker)
        uri = URI("#{session.url}/option-chains/#{ticker}/nested")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.to_s)
        request['Authorization'] = session.session_token
        response = http.request(request)
        raise StandardError, 'Error fetching "get_option_chain_data" API' unless response.code.to_i == 200

        JSON.parse(response.body)['data']['items'][0]
      end
    end
  end
end