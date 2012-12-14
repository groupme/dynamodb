module DynamoDB
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
    THIRTY_SIX_HOURS = 129600

    # A SecurityTokenService is initialized for a single AWS user using his
    # credentials.
    def initialize(access_key_id, secret_access_key)
      @_access_key_id = access_key_id
      @_secret_access_key = secret_access_key
      @credentials = nil
    end

    def credentials
      obtain_credentials
      @credentials
    end

    private

    def signature(authorization_params)
      sign(string_to_sign(authorization_params))
    end

    # The last line needs to be a query string of all parameters
    # in the request in alphabetical order.
    def string_to_sign(authorization_params)
      [
        "GET",
        "sts.amazonaws.com",
        "/",
        "AWSAccessKeyId=#{@_access_key_id}" +
          "&Action=GetSessionToken" +
          "&DurationSeconds=#{THIRTY_SIX_HOURS}" +
          "&SignatureMethod=HmacSHA256" +
          "&SignatureVersion=2" +
          "&Timestamp=#{CGI.escape(authorization_params[:Timestamp])}" +
          "&Version=2011-06-15"
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
      return unless credentials_expired?

      authorization_params = {
        :Action           => 'GetSessionToken',
        :Timestamp        => Time.now.utc.iso8601,
        :Version          => '2011-06-15',
        :DurationSeconds  => THIRTY_SIX_HOURS # 36 hour expiration
      }

      params = {
        :AWSAccessKeyId   => @_access_key_id,
        :SignatureMethod  => 'HmacSHA256',
        :SignatureVersion => '2',
        :Signature        => signature(authorization_params)
      }.merge(authorization_params)

      uri = URI("https://sts.amazonaws.com")
      uri.query = URI.encode_www_form(params)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(Net::HTTP::Get.new(uri.request_uri))
      end

      if response.is_a?(Net::HTTPSuccess)
        body = response.body
        @expiration = Time.parse(get_tag(:Expiration, body))
        @credentials = Credentials.new(
          get_tag(:AccessKeyId, body),
          get_tag(:SecretAccessKey, body),
          get_tag(:SessionToken, body))
      else
        raise AuthenticationError.new(response)
      end
    end

    # Sign (HMAC-SHA256) a string using the secret key given at
    # initialization.
    def sign(string)
      Base64.encode64(
        OpenSSL::HMAC.digest('sha256', @_secret_access_key, string)
      ).strip
    end

    def credentials_expired?
      @expiration.nil? || @expiration <= Time.now.utc
    end
  end
end
