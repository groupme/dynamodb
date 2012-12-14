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

      request = DynamoDB::Request.new(uri, credentials, operation, data)
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
