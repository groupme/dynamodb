module DynamoDB
  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    DEFAULT_HOST = "dynamodb.us-east-1.amazonaws.com"

    class << self
      def http_handler
        @http_handler ||= HttpHandler.new
      end

      def http_handler=(new_http_handler)
        @http_handler = new_http_handler
      end
    end

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
      @uri     = URI(opts[:uri] || "https://#{endpoint}/")

      set_timeout(opts[:timeout]) if opts[:timeout]
    end

    # Create and send a request to DynamoDB
    #
    # This returns either a SuccessResponse or a FailureResponse.
    #
    # `operation` can be any DynamoDB operation. `data` is a hash that will be
    # used as the request body (in JSON format). More info available at:
    # http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide
    #
    def post(operation, data={})
      credentials = @sts.credentials

      request = DynamoDB::Request.new(
        uri:         @uri,
        credentials: credentials,
        operation:   operation,
        data:        data
      )
      http_handler.handle(request)
    end

    private

    def http_handler
      self.class.http_handler
    end

    def set_timeout(timeout)
      http_handler.timeout = timeout
    end
  end
end
