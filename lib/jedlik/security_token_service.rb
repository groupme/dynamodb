module Jedlik

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

    private

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
        response = Typhoeus::Request.get(request_uri)
        if response.success?
          body = response.body
          @session_token      = get_tag(:SessionToken, body)
          @secret_access_key  = get_tag(:SecretAccessKey, body)
          @expiration         = Time.parse(get_tag(:Expiration, body))
          @access_key_id      = get_tag(:AccessKeyId, body)
        else
          raise "credential errors: #{response.inspect}"
        end
      end
    end

    # Generate the params to be sent to STS.
    def request_params
      {
        :AWSAccessKeyId   => @_access_key_id,
        :Action           => 'GetSessionToken',
        :DurationSeconds  => '3600',
        :SignatureMethod  => 'HmacSHA256',
        :SignatureVersion => '2',
        :Timestamp        => Time.now.utc.iso8601,
        :Version          => '2011-06-15',
      }
    end

    # Generate the URI that should be requested.
    def request_uri
      qs = request_params.map { |key, val|
        [CGI.escape(key.to_s), CGI.escape(val)].join('=')
      }.join('&')

      "https://sts.amazonaws.com/?#{qs}&Signature=" +
      CGI.escape(sign("GET\nsts.amazonaws.com\n/\n#{qs}"))
    end

    # Sign (HMAC-SHA256) a string using the secret key given at
    # initialization.
    def sign(string)
      digested = OpenSSL::HMAC.digest('sha256', @_secret_access_key, string)
      Base64.encode64(digested).chomp
    end
  end
end
