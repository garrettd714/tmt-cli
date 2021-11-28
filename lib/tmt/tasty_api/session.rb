# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'openssl'
require 'json'

module Tmt
  module TastyApi
    # Auth with Tastyworks and get session token
    class Session
      attr_reader :session_token, :url, :logged_in

      def initialize(username, password, url = nil)
        @username = username
        @password = password
        @url = url || 'https://api.tastyworks.com'
        @logged_in = false
        @session_token = get_session_token
      end

      def get_session_token
        if @logged_in && @session_token
          return @session_token if (Time.now - @logged_in_at) < 60
        end

        body = {
          login: @username,
          password: @password
        }
        uri = URI("#{@url}/sessions")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.to_s)
        request.set_form_data(body)
        response = http.request(request)

        if response.code.to_i != 201
          @logged_in = false
          @logged_in_at = nil
          @session_token = nil
        end

        @logged_in = true
        @logged_in_at = Time.now
        @session_token = JSON.parse(response.read_body)&.[]('data')&.[]('session-token')
        validate_session

        @session_token
      end

      def validate_session
        uri = URI("#{@url}/sessions/validate")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Post.new(uri.to_s)
        request['Authorization'] = @session_token
        response = http.request(request)

        if response.code.to_i != 201
          @logged_in = false
          @logged_in_at = nil
          @session_token = nil
          raise StandardError, 'Could not validate session'
        end
        true
      end

      def request_headers
        { 'Authorization' => @session_token }
      end

      def active?
        validate_session
      end
    end
  end
end
