![Dependency Status](https://gemnasium.com/aereal/omniauth-xauth.png)

![Build Status](https://secure.travis-ci.org/aereal/omniauth-xauth.png)


# OmniAuth XAuth

OmniAuth XAuth strategy for use in [OmniAuth](https://github.com/intridea/omniauth) 1.0 strategy development.

This gem contains a generic XAuth strategy for OmniAuth. It is meant to
serve as a building block strategy for other strategies and not to be
used independently (since it has no inherent way to gather uid and user
info).

The XAuth form is rendered as an [OmniAuth Form](http://rubydoc.info/github/intridea/omniauth/master/OmniAuth/Form)
and can be styled as such.

## Creating an XAuth Strategy

To create an OmniAuth XAuth strategy using this gem, you can simply
subclass it and add a few extra methods like so:

    require 'omniauth-xauth'

    module OmniAuth
      module Strategies
        class SomeSite < OmniAuth::Strategies::XAuth
          option :client_options, {
            :site               => 'http://www.service.com/',
            :access_token_url   => 'https://www.service.com/oauth/access_token'
          }
          option :xauth_options, { :title => 'XAuth Login Form Header'}


          # This is where you pass the options you would pass when
          # initializing your consumer from the OAuth gem.


          uid { raw_info['uid'] }
          info do
            {
              :name => raw_info['name'],
              :email => raw_info['email']
            }
          end

          extra do
            {
              'raw_info' => raw_info
            }
          end

          def raw_info
            @raw_info ||= MultiJson.decode(access_token.get('/me.json').body)
          end
        end
      end
    end
