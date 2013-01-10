require "net/http/connection_pool"

module DynamoDB
  # Process HTTP requests
  #
  # Kudos to AWS's NetHttpHandler class for the inspiration here.
  # Re-using a single instance of this class is recommended, since
  # it relies upon persistent HTTP connections managed by a pool.
  class HttpHandler
    DEFAULT_TIMEOUT = 5 # seconds

    NETWORK_ERRORS = [
      SocketError,
      EOFError,
      IOError,
      Errno::ECONNABORTED,
      Errno::ECONNRESET,
      Errno::EPIPE,
      Errno::EINVAL,
      Timeout::Error,
      Errno::ETIMEDOUT
    ]

    attr_writer :timeout

    def initialize(options = {})
      @pool    = Net::HTTP::ConnectionPool.new
      @timeout = options[:timeout] || DEFAULT_TIMEOUT
    end

    # Perform an HTTP request
    #
    # The argument should be a `DynamoDB::Request` object, and the
    # return value is either a `DynamoDB::SuccessResponse` or a
    # `DynamoDB::FailureResponse`.
    def handle(request)
      connection = @pool.connection_for(request.uri.host, {
        port:            request.uri.port,
        ssl:             request.uri.scheme == "https",
        ssl_verify_peer: true
      })
      connection.read_timeout = @timeout

      begin
        response = nil
        connection.request(build_http_request(request)) do |http_response|
          if http_response.code.to_i < 300
            response = SuccessResponse.new(http_response)
          else
            response = FailureResponse.new(http_response)
          end
        end
        response
      rescue *NETWORK_ERRORS => e
        FailureResponse.new.tap do |response|
          response.body = nil
          response.code = nil
          response.error = e
        end
      end
    end

    def build_http_request(request)
      Net::HTTP::Post.new(request.uri.to_s).tap do |http_request|
        http_request.body = request.body

        request.headers.each do |key, value|
          http_request[key] = value
        end
      end
    end

  end
end
