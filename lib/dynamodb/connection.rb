module DynamoDB
  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    DEFAULT_HOST = "dynamodb.us-east-1.amazonaws.com"

    # Acceptable `opts` keys are:
    #
    #     :endpoint # DynamoDB endpoint to use, default 'dynamodb.us-east-1.amazonaws.com'
    #     :uri      # Specify a URI instead: 'https://dynamodb.us-east-1.amazonaws.com/'
    #     :timeout  # HTTP timeout, default 5 seconds
    #
    def initialize(opts = {})
      if opts[:token_service]
        @sts = opts[:token_service]
      elsif opts[:access_key_id] && opts[:secret_access_key]
        @sts = SecurityTokenService.new(opts[:access_key_id], opts[:secret_access_key])
      else
        raise ArgumentError.new("access_key_id and secret_access_key are required")
      end

      endpoint = opts[:endpoint] || DEFAULT_HOST
      @timeout = opts[:timeout]
      @uri     = opts[:uri] || URI("https://#{endpoint}/")
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

      request = DynamoDB::Request.new(
        uri:         @uri,
        credentials: credentials,
        operation:   operation,
        data:        data,
        timeout:     @timeout
      )
      response = request.response

      case operation
      when :Query, :Scan, :GetItem
        DynamoDB::Response.new(response)
      else
        MultiJson.load(response.body)
      end
    end
  end
end
