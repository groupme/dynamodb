require "net/https"

module DynamoDB
  class Request
    class << self
      def digest(signing_string, key)
        Base64.encode64(
          OpenSSL::HMAC.digest('sha256', key, Digest::SHA256.digest(signing_string))
        ).strip
      end
    end

    def initialize(uri, credentials, operation, data)
      @uri         = uri
      @credentials = credentials
      @operation   = operation
      @data        = data
    end

    def signed_http_request
      @signed_http_request ||= http_request.tap do |request|
        request["x-amzn-authorization"] = "AWS3 AWSAccessKeyId=#{@credentials.access_key_id},Algorithm=HmacSHA256,Signature=#{signature}"
      end
    end

    def http_request
      @http_request ||= Net::HTTP::Post.new(@uri.to_s).tap do |request|
        request.body = body

        request["accept"]               = "*/*"
        request["user-agent"]           = "DynamoDB/1.0.0"
        request["host"]                 = @uri.host
        request["content-type"]         = "application/x-amz-json-1.0"
        request["x-amz-date"]           = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
        request["x-amz-security-token"] = @credentials.session_token
        request["x-amz-target"]         = "DynamoDB_20111205.#{@operation}"
      end
    end

    def signature
      amazon_headers = http_request.each_header.to_a.select { |key, val| key =~ /\Ax-amz-/ }
      amazon_header_string = amazon_headers.sort.map { |key, val| [key, val].join(':') + "\n" }.join
      signing_string = "POST\n/\n\nhost:#{@uri.host}\n#{amazon_header_string}\n#{body}"
      self.class.digest(signing_string, @credentials.secret_access_key)
    end

    def response
      begin
        http_response = Net::HTTP.start(@uri.host, @uri.port, use_ssl: (@uri.scheme == "https")) do |http|
          http.request(signed_http_request)
        end

        if http_response.is_a?(Net::HTTPSuccess)
          http_response
        else
          raise_error(http_response)
        end
      rescue Timeout::Error
        raise TimeoutError.new
      end
    end

    private

    def body
      @body ||= MultiJson.dump(@data)
    end

    def raise_error(http_response)
      case http_response
      when Net::HTTPClientError
        raise ClientError.new(http_response)
      when Net::HTTPServerError
        raise ServerError.new(http_response)
      else
        if http_response.code == "0"
          raise ServerError.new(http_response)
        else
          raise BaseError.new(http_response)
        end
      end
    end
  end
end
