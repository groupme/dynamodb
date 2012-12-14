require "net/https"

module DynamoDB
  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    DEFAULTS = {
      :endpoint => 'dynamodb.us-east-1.amazonaws.com',
      :timeout  => 5000 # ms
    }

    # Acceptable `opts` keys are:
    #
    #     :endpoint # DynamoDB endpoint to use.
    #               # Default: 'dynamodb.us-east-1.amazonaws.com'
    #
    def initialize(opts = {})
      opts = DEFAULTS.merge opts

      if opts[:token_service]
        @sts = opts[:token_service]
      elsif opts[:access_key_id] && opts[:secret_access_key]
        @sts = SecurityTokenService.new(opts[:access_key_id], opts[:secret_access_key])
      else
        raise ArgumentError.new("access_key_id and secret_access_key are required")
      end

      @endpoint = opts[:endpoint]
      @timeout  = opts[:timeout]
    end

    def uri
      @uri ||= URI("https://#{@endpoint}/")
    end

    # Create and send a request to DynamoDB.
    # Returns a hash extracted from the response body.
    #
    # `operation` can be any DynamoDB operation. `data` is a hash that will be
    # used as the request body (in JSON format). More info available at:
    #
    # http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide
    #
    def post(operation, data={})
      credentials = @sts.credentials

      begin
        response = Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == "https")) do |http|
          request = new_request(credentials, operation, MultiJson.dump(data))
          http.request(request)
        end
      rescue Timeout::Error
        raise TimeoutError.new(response)
      end

      if response.is_a?(Net::HTTPSuccess)
        case operation
        when :Query, :Scan, :GetItem
          DynamoDB::Response.new(response)
        else
          MultiJson.load(response.body)
        end
      else
        raise_error(response)
      end
    end

    private

    def new_request(credentials, operation, body)
      request = Net::HTTP::Post.new(uri.to_s)
      request.body = body
      request["host"]                 = uri.host
      request["content-type"]         = "application/x-amz-json-1.0"
      request["x-amz-date"]           = Time.now.utc.strftime("%a, %d %b %Y %H:%M:%S GMT")
      request["x-amz-security-token"] = credentials.session_token
      request["x-amz-target"]         = "DynamoDB_20111205.#{operation}"

      get_amz_headers = request.each_header.to_a.select { |key, val| key =~ /\Ax-amz-/ }
      amz_to_sts = get_amz_headers.sort.map { |key, val| [key, val].join(':') + "\n" }.join
      string_to_sign = "POST\n/\n\nhost:#{uri.host}\n#{amz_to_sts}\n#{body}"
      request["x-amzn-authorization"] = "AWS3 AWSAccessKeyId=#{credentials.access_key_id},Algorithm=HmacSHA256,Signature=#{digest(string_to_sign, credentials.secret_access_key)}"

      request
    end

    def digest(string_to_sign, key)
      Base64.encode64(
        OpenSSL::HMAC.digest('sha256', key, Digest::SHA256.digest(string_to_sign))
      ).strip
    end

    def raise_error(response)
      case response
      when Net::HTTPClientError
        raise ClientError.new(response)
      when Net::HTTPServerError
        raise ServerError.new(response)
      else
        if response.code == "0"
          raise ServerError.new(response)
        else
          raise BaseError.new(response)
        end
      end
    end
  end
end
