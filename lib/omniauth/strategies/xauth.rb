require 'omniauth/oauth'
require 'multi_json'

module OmniAuth
  module Strategies
    class XAuth
      include OmniAuth::Strategy

      args [:consumer_key, :consumer_secret]

      option :consumer_options, {}

      def request_phase
        session['oauth'] ||= {}
        if env['REQUEST_METHOD'] == 'GET'
          get_credentials
        else
          session['omniauth.xauth'] = { 'x_auth_mode' => 'client_auth', 'x_auth_username' => request['username'], 'x_auth_password' => request['password'] }
          redirect callback_path
        end
      end

      def get_credentials
        OmniAuth::Form.build(consumer_options[:title] || "xAuth Credentials") do
          text_field 'Username', 'username'
          password_field 'Password', 'password'
        end.to_response
      end

      def consumer
        ::OAuth::Consumer.new(consumer_key, consumer_secret, consumer_options.merge(options[:client_options] || options[:consumer_options] || {}))
      end

      def callback_phase
        @access_token = consumer.get_access_token(nil, {}, session['omniauth.xauth'])
        super
      rescue ::Net::HTTPFatalError => e
        fail!(:service_unavailable, e)
      rescue ::OAuth::Unauthorized => e
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
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
