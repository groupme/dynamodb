require "aws4/signer"

module DynamoDB
  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    class << self
      def http_handler
        @http_handler ||= HttpHandler.new
      end

      def http_handler=(new_http_handler)
        @http_handler = new_http_handler
      end
    end

    # Create a connection
    # uri:          # default 'https://dynamodb.us-east-1.amazonaws.com/'
    # timeout:      # default 5 seconds
    # api_version:  # default
    #
    def initialize(opts = {})
      if !(opts[:access_key_id] && opts[:secret_access_key])
        raise ArgumentError.new("access_key_id and secret_access_key are required")
      end

      set_timeout(opts[:timeout]) if opts[:timeout]

      @access_key_id = opts[:access_key_id]
      @secret_access_key = opts[:secret_access_key]
      @uri = URI(opts[:uri] || "https://dynamodb.us-east-1.amazonaws.com/")
      @region = @uri.host.split(".", 4)[1] || "us-east-1"
      @api_version = opts[:api_version] || "DynamoDB_20111205"
    end

    # Create and send a request to DynamoDB
    #
    # This returns either a SuccessResponse or a FailureResponse.
    #
    # `operation` can be any DynamoDB operation. `body` is a hash that will be
    # used as the request body (in JSON format). More info available at:
    # http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide
    #
    def post(operation, body={})
      signer = AWS4::Signer.new(
        access_key: @access_key_id,
        secret_key: @secret_access_key,
        region: @region
      )
      request = DynamoDB::Request.new(
        signer: signer,
        uri: @uri,
        operation: version(operation),
        body: body
      )
      http_handler.handle(request)
    end

    private

    def version(op)
      "#{@api_version}.#{op}"
    end

    def http_handler
      self.class.http_handler
    end

    def set_timeout(timeout)
      http_handler.timeout = timeout
    end
  end
end
