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

    attr_reader :uri, :datetime, :credentials, :region, :data, :service, :operation, :api_version

    def initialize(args = {})
      @uri          = args[:uri]
      @credentials  = args[:credentials]
      @operation    = args[:operation]
      @data         = args[:data]
      @api_version  = args[:api_version]
      @region       = args[:region] || "us-east-1"
      @datetime     = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      @service      = "dynamodb"
    end

    def our_headers
      {
        "user-agent"           => "DynamoDB/#{DynamoDB::VERSION}",
        "host"                 => uri.host,
        "content-type"         => "application/x-amz-json-1.0",
        "content-length"       => body.size,
        "x-amz-date"           => datetime,
        "x-amz-target"         => "#{api_version}.#{operation}",
        "x-amz-content-sha256" => hexdigest(body || '')
      }
    end

    def headers
      @headers ||= our_headers.merge("authorization" => authorization)
    end

    def body
      @body ||= MultiJson.dump(data)
    end

    def authorization
      parts = []
      parts << "AWS4-HMAC-SHA256 Credential=#{credentials.access_key_id}/#{credential_string}"
      parts << "SignedHeaders=#{our_headers.keys.sort.join(";")}"
      parts << "Signature=#{signature}"
      parts.join(', ')
    end

    def signature
      k_secret = credentials.secret_access_key
      k_date = hmac("AWS4" + k_secret, datetime[0,8])
      k_region = hmac(k_date, region)
      k_service = hmac(k_region, service)
      k_credentials = hmac(k_service, 'aws4_request')
      hexhmac(k_credentials, string_to_sign)
    end

    def string_to_sign
      parts = []
      parts << 'AWS4-HMAC-SHA256'
      parts << datetime
      parts << credential_string
      parts << hexdigest(canonical_request)
      parts.join("\n")
    end

    def credential_string
      parts = []
      parts << datetime[0,8]
      parts << region
      parts << service
      parts << 'aws4_request'
      parts.join("/")
    end

    def canonical_request
      parts = []
      parts << "POST"
      parts << uri.path
      parts << uri.query
      parts << our_headers.sort.map {|k, v| [k,v].join(':')}.join("\n") + "\n"
      parts << "content-length;content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target"
      parts << our_headers['x-amz-content-sha256']
      parts.join("\n")
    end

    def hexdigest value
      digest = Digest::SHA256.new
      digest.update(value)
      digest.hexdigest
    end

    def hmac key, value
      OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, value)
    end

    def hexhmac key, value
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), key, value)
    end
  end
end
