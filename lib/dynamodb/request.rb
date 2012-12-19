require "base64"
require "openssl"

module DynamoDB
  class Request
    class << self
      def digest(signing_string, key)
        Base64.encode64(
          OpenSSL::HMAC.digest('sha256', key, Digest::SHA256.digest(signing_string))
        ).strip
      end
    end

    attr_reader :uri

    def initialize(args = {})
      @uri         = args[:uri]
      @credentials = args[:credentials]
      @operation   = args[:operation]
      @data        = args[:data]
    end

    def headers
      @headers ||= amazon_headers.merge(
        "accept"               => "*/*",
        "user-agent"           => "DynamoDB/1.0.0",
        "host"                 => @uri.host,
        "content-type"         => "application/x-amz-json-1.0",
        "x-amzn-authorization" => "AWS3 AWSAccessKeyId=#{@credentials.access_key_id},Algorithm=HmacSHA256,Signature=#{signature}"
      )
    end

    def body
      @body ||= MultiJson.dump(@data)
    end

    def signature
      amazon_header_string = amazon_headers.sort.map { |key, val| [key, val].join(':') + "\n" }.join
      signing_string = "POST\n/\n\nhost:#{@uri.host}\n#{amazon_header_string}\n#{body}"
      self.class.digest(signing_string, @credentials.secret_access_key)
    end

    private

    def amazon_headers
      @amazon_headers ||= {
        "x-amz-date"           => Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT"),
        "x-amz-security-token" => @credentials.session_token,
        "x-amz-target"         => "DynamoDB_20111205.#{@operation}",
      }
    end
  end
end
