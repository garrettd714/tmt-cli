# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'json'

module Tmt
  # Rapid Api Integration (to fetch stock/etf prices and option chains)
  class GetOptions
    attr_reader :ticker

    def initialize(ticker)
      @ticker = ticker
    end

    def self.call(ticker, &block)
      new(ticker).fetch(&block)
    end

    def fetch
      url = URI("https://option-chain.p.rapidapi.com/options/#{ticker.downcase}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request['x-rapidapi-host'] = 'option-chain.p.rapidapi.com'
      request['x-rapidapi-key'] = '9caff36cbfmsh013515964f8d7abp126e99jsnba1ebad88996'

      response = http.request(request)
      raise StandardError, "Error fetching live data for #{ticker.upcase}. Enter trade 'mark' ['ticker_price'] manually\n" if response.code != '200'

      JSON.parse(response.read_body)
    end
  end
end

# {
#   stock: {
#     bid: float,
#     ask: float,
#     open: float
#   },
#   options: [
#     {
#       "{YYYY-MM-DD}": {
#         calls: [
#           {
#             strike: float,
#             bid: float,
#             ask: float,
#             percentChange: float,
#             iv: float
#           }
#         ],
#         puts: [
#           {
#             strike: float,
#             bid: float,
#             ask: float,
#             percentChange: float,
#             iv: float
#           }
#         ]
#       }
#     }
#   ]
# }
