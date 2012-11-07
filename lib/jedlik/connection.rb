module Jedlik
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

      request = new_request(credentials, operation, MultiJson.dump(data))
      request.sign(credentials)

      hydra.queue(request)
      hydra.run
      response = request.response

      if response.success?
        case operation
        when :Query, :Scan, :GetItem
          Jedlik::Response.new(response)
        else
          MultiJson.load(response.body)
        end
      else
        raise_error(response)
      end
    end

    private

    def hydra
      Typhoeus::Hydra.hydra
    end

    def new_request(credentials, operation, body)
      Typhoeus::Request.new "https://#@endpoint/",
        :method  => :post,
        :body    => body,
        :timeout => @timeout,
        :connect_timeout => @timeout,
        :headers => {
          'host'                 => @endpoint,
          'content-type'         => "application/x-amz-json-1.0",
          'x-amz-date'           => (Time.now.utc.strftime "%a, %d %b %Y %H:%M:%S GMT"),
          'x-amz-security-token' => credentials.session_token,
          'x-amz-target'         => "DynamoDB_20111205.#{operation}",
        }
    end

    def raise_error(response)
      if response.timed_out?
        raise TimeoutError.new(response)
      else
        case response.code
        when 400..499
          raise ClientError.new(response)
        when 500..599
          raise ServerError.new(response)
        when 0
          raise ServerError.new(response)
        else
          raise BaseError.new(response)
        end
      end
    end
  end
end
