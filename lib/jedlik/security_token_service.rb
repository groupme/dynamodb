module Jedlik
  attr_writer :access_key_id
  attr_writer :secret_acces_key
  attr_writer :session_token

  # SecurityTokenService automatically manages the creation and renewal of
  # temporary AWS credentials.
  #
  # Usage:
  #
  #     credentials = SecurityTokenService.new "id", "secret key"
  #     credentials.access_key_id     # => String
  #     credentials.secret_access_key # => String
  #     credentials.session_token     # => String
  #
  class SecurityTokenService
    # A SecurityTokenService is initialized for a single AWS user using his
    # credentials.
    def initialize(access_key_id, secret_access_key)
      @_access_key_id = access_key_id
      @_secret_access_key = secret_access_key
    end

    # Get a temporary access key id from STS or from cache.
    def access_key_id
      obtain_credentials
      @access_key_id
    end

    # Get a temporary secret access key from STS or from cache.
    def secret_access_key
      obtain_credentials
      @secret_access_key
    end

    # Get a temporary session token from STS or from cache.
    def session_token
      obtain_credentials
      @session_token
    end

    def refresh_credentials
      @expiration = nil
      obtain_credentials
    end

    private

    def signature
      sign(string_to_sign)
    end

    def string_to_sign
      [
        "GET",
        "sts.amazonaws.com",
        "/",
        "AWSAccessKeyId=#{@_access_key_id}&Action=GetSessionToken&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=#{CGI.escape(authorization_params[:Timestamp])}&Version=2011-06-15"
      ].join("\n")
    end

    # Extract the contents of a given tag.
    def get_tag(tag, string)
      # Considering that the XML string received from STS is sane and always
      # has the same simple structure, I think a simple regular expression
      # can do the job (with the benefit of not adding a dependency on
      # another library just for ONE method). I will switch to Nokogiri if
      # needed.
      string.match(/#{tag.to_s}>([^<]*)/)[1]
    end

    # Obtain temporary credentials, set to expire after 1 hour. If
    # credentials were previously obtained, no request is made until they
    # expire.
    def obtain_credentials
      if not @expiration or @expiration <= Time.now.utc
        params = {
          :AWSAccessKeyId   => @_access_key_id,
          :SignatureMethod  => 'HmacSHA256',
          :SignatureVersion => '2',
          :Signature        => signature
        }.merge(authorization_params)

        response = Typhoeus::Request.get("https://sts.amazonaws.com", :params => params)
        if response.success?
          body = response.body
          @session_token      = get_tag(:SessionToken, body)
          @secret_access_key  = get_tag(:SecretAccessKey, body)
          @expiration         = Time.parse(get_tag(:Expiration, body))
          @access_key_id      = get_tag(:AccessKeyId, body)
        else
          raise Jedlik::AuthenticationError.new(response.inspect)
        end
      end
    end

    def authorization_params
      {
        :Action           => 'GetSessionToken',
        :Timestamp        => Time.now.utc.iso8601,
        :Version          => '2011-06-15'
      }
    end

    # Sign (HMAC-SHA256) a string using the secret key given at
    # initialization.
    def sign(string)
      Base64.encode64(
        OpenSSL::HMAC.digest('sha256', @_secret_access_key, string)
      ).strip
    end
  end
end
