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

  it 'should add a camelization for itself' do
    OmniAuth::Utils.camelize('xauth').should == 'XAuth'
  end

  describe '/auth/{name}' do
    context 'GET' do
      before do
        get '/auth/example.org'
      end

      it 'should render an Omniauth::Form' do
        last_response.should be_ok
        last_response.body.should include('Username')
        last_response.body.should include('Password')
      end
    end

    context 'POST' do
      before do
        post '/auth/example.org', :username => 'joe', :password => 'passw0rd'
      end

      it 'should redirect to the callback url' do
        last_response.should be_redirect
        last_response.headers['Location'].should eq('/auth/example.org/callback')
      end

      it 'sets the xauth credentials to the "omniauth.xauth" session' do
        session['omniauth.xauth'].should be
        session['omniauth.xauth']['x_auth_username'].should eq('joe')
        session['omniauth.xauth']['x_auth_password'].should eq('passw0rd')

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

      it 'should clear "omniauth.xauth" from the session' do
        session['omniauth.xauth'].should be_nil
      end

      it 'should exchange the request token for an access token' do
        last_request.env['omniauth.auth']['provider'].should == 'example.org'
        last_request.env['omniauth.auth']['extra']['access_token'].should be_kind_of(OAuth::AccessToken)
      end

      it 'should call through to the master app' do
        last_response.body.should == 'true'
      end
    end

    context "bad gateway (or any 5xx) for access_token" do
      before do
        stub_request(:post, 'https://api.example.org/oauth/access_token').
           to_raise(::Net::HTTPFatalError.new(%Q{502 "Bad Gateway"}, nil))
        get '/auth/example.org/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::Net::HTTPFatalError)
        last_request.env['omniauth.error.type'] = :service_unavailable
      end
    end

    context "SSL failure" do
      before do
        stub_request(:post, 'https://api.example.org/oauth/access_token').
           to_raise(::OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"))
        get '/auth/example.org/callback', {:oauth_verifier => 'dudeman'}, {'rack.session' => { 'omniauth.xauth' => { 'x_auth_mode' => 'client_auth', 'x_auth_username' => 'username', 'x_auth_password' => 'password' }}}
      end

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::OpenSSL::SSL::SSLError)
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

      it 'should call fail! with :service_unavailable' do
        last_request.env['omniauth.error'].should be_kind_of(::OAuth::Unauthorized)
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

    it 'should call fail! with :session_expired' do
      last_request.env['omniauth.error'].should be_kind_of(::OmniAuth::NoSessionError)
      last_request.env['omniauth.error.type'] = :session_expired
    end
  end
end
