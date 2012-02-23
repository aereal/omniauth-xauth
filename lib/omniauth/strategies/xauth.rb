require 'omniauth'
require 'multi_json'
require 'oauth'

module OmniAuth
  module Strategies
    class XAuth
      include OmniAuth::Strategy

      args [:consumer_key, :consumer_secret]
      option :consumer_key, nil
      option :consumer_secret, nil
      option :client_options, {}
      option :consumer_options, {}
      option :xauth_options, { :title => 'OmniAuth XAuth' }

      attr_reader :access_token

      def request_phase
        if env['REQUEST_METHOD'] == 'GET'
          get_credentials
        else
          session['omniauth.xauth'] = { 'x_auth_mode' => 'client_auth', 'x_auth_username' => request['username'], 'x_auth_password' => request['password'] }
          redirect callback_path
        end
      end

      def get_credentials
        OmniAuth::Form.build(options.xauth_options) do
          text_field 'Username', 'username'
          password_field 'Password', 'password'
        end.to_response
      end

      def consumer
        consumer = ::OAuth::Consumer.new(options.consumer_key, options.consumer_secret, options.client_options)
        consumer.http.open_timeout = options.open_timeout if options.open_timeout
        consumer.http.read_timeout = options.read_timeout if options.read_timeout
        consumer
      end

      def callback_phase
        raise OmniAuth::NoSessionError.new("Session Expired") if session['omniauth.xauth'].nil?

        @access_token = consumer.get_access_token(nil, {}, session['omniauth.xauth'])
        super
      rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError => e
        fail!(:service_unavailable, e)
      rescue ::OAuth::Unauthorized => e
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
      rescue ::OmniAuth::NoSessionError => e
        fail!(:session_expired, e)
      rescue => e
        puts e.backtrace
      ensure
        session['omniauth.xauth'] = nil
      end

      credentials do
        {'token' => @access_token.token, 'secret' => @access_token.secret}
      end

      extra do
        {'access_token' => @access_token}
      end
    end
  end
end

OmniAuth.config.add_camelization 'xauth', 'XAuth'
