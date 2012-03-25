module Jedlik

  # Establishes a connection to Amazon DynamoDB using credentials.
  class Connection
    attr_reader :sts

    DEFAULTS = {
      :endpoint => 'dynamodb.us-east-1.amazonaws.com',
    }

    # Acceptable `opts` keys are:
    #
    #     :endpoint # DynamoDB endpoint to use.
    #               # Default: 'dynamodb.us-east-1.amazonaws.com'
    #
    def initialize(access_key_id, secret_access_key, opts={})
      opts = DEFAULTS.merge opts
      @sts = SecurityTokenService.new(access_key_id, secret_access_key)
      @endpoint = opts[:endpoint]
      @debug = opts[:debug]
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
      request = new_request(operation, Yajl::Encoder.encode(data))
      request.sign(sts)
      hydra.queue(request)
      hydra.run
      response = request.response
      puts response.inspect if @debug

      if response.code == 200
        Yajl::Parser.parse(response.body)
      else
        raise_error(response)
      end
    end

    private

    def hydra
      Typhoeus::Hydra.hydra
    end

    def new_request(operation, body)
      Typhoeus::Request.new "https://#{@endpoint}/",
        :method   => :post,
        :body     => body,
        :headers  => {
          'host'                  => @endpoint,
          'content-type'          => "application/x-amz-json-1.0",
          'x-amz-date'            => (Time.now.utc.strftime "%a, %d %b %Y %H:%M:%S GMT"),
          'x-amz-security-token'  => sts.session_token,
          'x-amz-target'          => "DynamoDB_20111205.#{operation}",
        }
    end

    def raise_error(response)
      case response.code
      when 400..499
        raise ClientError, response.body
      when 500..599
        raise ServerError, response.code
      else
        raise Exception, response.body
      end
    end
  end
end
