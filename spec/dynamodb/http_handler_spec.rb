require "spec_helper"

describe DynamoDB::HttpHandler do
  describe "#handle" do
    let(:http_handler) { DynamoDB::HttpHandler.new }
    let(:request) {
      stub(DynamoDB::Request,
        uri:     URI("https://dynamo.local/"),
        headers: {},
        body:    "{}"
      )
    }

    it "performs an HTTP request given a DynamoDB::Request" do
      http_request = stub_request(:post, "https://dynamo.local/").to_return(status: 200)
      http_handler.handle(request)
      http_request.should have_been_requested
    end

    it "returns a DynamoDB::SuccessResponse for successes" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 200)

      response = http_handler.handle(request)
      response.should be_an_instance_of(DynamoDB::SuccessResponse)
      response.should be_success
    end

    it "returns a DynamoDB::Response for failures" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 500, body: "Server errors")

      response = http_handler.handle(request)
      response.should be_an_instance_of(DynamoDB::FailureResponse)
      response.should_not be_success
    end

    it "returns a DynamoDB::Response for network errors" do
      error = Errno::ECONNRESET.new
      stub_request(:post, "https://dynamo.local/").to_raise(error)

      response = http_handler.handle(request)
      response.should be_an_instance_of(DynamoDB::FailureResponse)
      response.should_not be_success
      response.error.should == error
    end

    it "respects a custom timeout option (set on initialize)" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 200)
      connection = Net::HTTP::ConnectionPool::Connection.any_instance
      connection.should_receive(:read_timeout=).with(5)
      http_handler.handle(request)
    end
  end

  describe "#build_http_request" do
    it "converts a DynamoDB::Request into a Net::HTTP::Post" do
      request = stub(DynamoDB::Request,
        uri:      URI("https://dynamo.local/"),
        headers:  {"content-type" => "application/json"},
        body:     "POST body"
      )

      http_handler = DynamoDB::HttpHandler.new
      http_request = http_handler.build_http_request(request)
      http_request.should be_an_instance_of(Net::HTTP::Post)
      http_request.path.should == "https://dynamo.local/"
      http_request["content-type"].should == "application/json"
      http_request.body.should == "POST body"
    end
  end
end
