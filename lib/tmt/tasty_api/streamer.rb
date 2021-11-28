# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'json'

# @UNUSED, keep around jik
module Tmt
  module TastyApi
    # Abandoned Data Streamer
    #   Couldn't find a `cometd` client, didn't want to replicate asycio/aiocometd client from tastyworks_api/streamer.py 11/25/21
    class Streamer
      attr_reader :session

      def initialize(session)
        @session = session
        raise StandardError, 'Tasty API session not active or valid' unless session.active?

        @cometd_client = nil
        @subs = {}
        setup_connection
      end

      private

      def setup_connection
        streamer_websocket_url

        # websockets
      end

      def streamer_websocket_url
        socket_url = streamer_data['data']['websocket-url']
        "#{socket_url}/cometd"
      end

      def streamer_token
        streamer_data['data']['token']
      end

      def streamer_data
        raise StandardError, 'Logged in session required' unless session.logged_in

        return @streamer_data if @streamer_data_created_at and (Time.now - @streamer_data_created_at) < 60

        uri = URI("#{session.url}/quote-streamer-tokens")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.to_s)
        request['Authorization'] = session.session_token
        response = http.request(request)

        @streamer_data_created_at = Time.now
        @streamer_data = JSON.parse(response.body)
      end
    end
  end
end

# #<Tmt::TastyApi::Streamer:0x00007fbdf8244718
# @cometd_client=nil,
# @session=
#  #<Tmt::TastyApi::Session:0x00007fbdfba2f6f0
#   @logged_in=true,
#   @logged_in_at=2021-11-24 20:03:07.744874 -0800,
#   @password="*************",
#   @session_token="n9l-eOJ82NUY0Whg_s1Uqem27u85pPYbkMNt_sPrubO__lJTeBlPPw+C",
#   @url="https://api.tastyworks.com",
#   @username="tastytrader*****">,
# @streamer_data=
#  {"data"=>
#    {"token"=>
#      "dGFzdHksbGl2ZSwsMTYzNzg5OTQ1NSwxNjM3ODEzMDU1LFU2ZDUwZTRiNC1hNDNmLTQ0M2UtOGEyMC05ZmJjODI0ZmYyYjM.MQyoFYVZnSBYuooVWfvS6utkgoGo22C37ezOfvdNSVE",
#     "streamer-url"=>"tasty-live.dxfeed.com:7301",
#     "websocket-url"=>"https://tasty-live-web.dxfeed.com/live",
#     "level"=>"live"},
#   "context"=>"/quote-streamer-tokens"},
# @streamer_data_created_at=2021-11-24 20:04:14.881883 -0800,
# @subs={}>
