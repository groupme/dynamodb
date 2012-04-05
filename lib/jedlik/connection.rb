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
      raise ArgumentError.new("access_key_id and secret_access_key are required") unless access_key_id && secret_access_key
      opts = DEFAULTS.merge opts
      @sts = SecurityTokenService.new(access_key_id, secret_access_key)
      @endpoint = opts[:endpoint]
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

      if response.code == 200
        case operation
        when :Query, :Scan, :GetItem
          Jedlik::Response.new(response)
        else
          Yajl::Parser.parse(response.body)
        end
      else
        if response.code == 403
          raise AuthenticationError
        else
          raise_error(response)
        end
      end
    end

    def credentials
      {
        :access_key_id      => @sts.access_key_id,
        :secret_access_key  => @sts.secret_access_key,
        :session_token      => @sts.session_token
      }
    end

    def credentials=(hash)
      raise ArgumentError unless hash.key?(:access_key_id) &&
                                 hash.key?(:secret_access_key) &&
                                 hash.key?(:session_token)

      @sts.access_key_id = hash[:access_key_id]
      @sts.secret_access_key = hash[:secret_access_key]
      @sts.session_token = hash[:session_token]
    end

    def authenticate
      @sts.refresh_credentials
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
