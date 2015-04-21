require 'spec_helper'

describe "OmniAuth::Strategies::XAuth" do
  class MyOAuthProvider < OmniAuth::Strategies::XAuth
    option :client_options, { :site => 'https://api.example.org', :title => 'xAuth', :access_token_url   => 'https://api.example.org/oauth/access_token' }
    option :consumer_options, {}
    uid { 1 }
    info{ { 'name' => 'ohai' } }
  end

  def app
    Rack::Builder.new {
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider MyOAuthProvider, 'abc', 'def', :name => 'example.org'
      end
      run lambda { |env| [404, {'Content-Type' => 'text/plain'}, [env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  def session
    last_request.env['rack.session']
  end

  it 'adds a camelization for itself' do
    expect(OmniAuth::Utils.camelize('xauth')).to eq('XAuth')
  end

  describe '/auth/{name}' do
    context 'GET' do
      before do
        get '/auth/example.org'
      end

      it 'renders an Omniauth::Form' do
        expect(last_response).to be_ok
        expect(last_response.body).to include('Username')
        expect(last_response.body).to include('Password')
      end
    end

    context 'POST' do
      before do
        post '/auth/example.org', :username => 'joe', :password => 'passw0rd'
      end

      it 'redirects to the callback url' do
        expect(last_response).to be_redirect
        expect(last_response.headers['Location']).to eq('/auth/example.org/callback')
      end

      it 'sets the xauth credentials to the "omniauth.xauth" session' do
        expect(session['omniauth.xauth']).to be
        expect(session['omniauth.xauth']['x_auth_username']).to eq('joe')
        expect(session['omniauth.xauth']['x_auth_password']).to eq('passw0rd')

      end
    end
  end

  describe '/auth/{name}/callback' do
    context 'Success' do
      before do
        stub_request(:post, 'https://api.example.org/oauth/access_token').
          to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
        get '/auth/example.org/callback', {}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'clears "omniauth.xauth" from the session' do
        expect(session['omniauth.xauth']).to be_nil
      end

      it 'exchanges the request token for an access token' do
        expect(last_request.env['omniauth.auth']['provider']).to eq('example.org')
        expect(last_request.env['omniauth.auth']['extra']['access_token']).to be_kind_of(OAuth::AccessToken)
      end

      it 'calls through to the master app' do
        expect(last_response.body).to eq('true')
      end
    end

    context "bad gateway (or any 5xx) for access_token" do
      before do
        stub_request(:post, 'https://api.example.org/oauth/access_token').
           to_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))
        get '/auth/example.org/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'calls fail! with :service_unavailable' do
        expect(last_request.env['omniauth.error']).to be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context "SSL failure" do
      before do
        stub_request(:post, 'https://api.example.org/oauth/access_token').
           to_raise(::OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
        get '/auth/example.org/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'calls fail! with :service_unavailable' do
        expect(last_request.env['omniauth.error']).to be_kind_of(::OpenSSL::SSL::SSLError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context 'Unauthorized failure' do
      before do
        response = Struct.new(:code, :message).new(401, "Unauthorized")
        stub_request(:post, 'https://api.example.org/oauth/access_token').
           to_raise(::OAuth::Unauthorized.new(response))
        get '/auth/example.org/callback', {}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'calls fail! with :service_unavailable' do
        expect(last_request.env['omniauth.error']).to be_kind_of(::OAuth::Unauthorized)
        last_request.env['omniauth.error.type'] = :invalid_credentials
      end
    end
  end

  describe '/auth/{name}/callback with expired session' do
    before do
      stub_request(:post, 'https://api.example.org/oauth/access_token').
         to_return(:body => "oauth_token=yourtoken&oauth_token_secret=yoursecret")
      get '/auth/example.org/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => {}}
    end

    it 'calls fail! with :session_expired' do
      expect(last_request.env['omniauth.error']).to be_kind_of(::OmniAuth::NoSessionError)
      last_request.env['omniauth.error.type'] = :session_expired
    end
  end
end
