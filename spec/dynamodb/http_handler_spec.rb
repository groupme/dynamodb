require "spec_helper"

describe DynamoDB::HttpHandler do
  describe "#handle" do
    let(:http_handler) { DynamoDB::HttpHandler.new }
    let(:request) {
      double(DynamoDB::Request,
        uri:     URI("https://dynamo.local/"),
        headers: {},
        body:    "{}"
      )
    }

    it "performs an HTTP request given a DynamoDB::Request" do
      http_request = stub_request(:post, "https://dynamo.local/").to_return(status: 200)
      http_handler.handle(request)
      expect(http_request).to have_been_requested
    end

    it "returns a DynamoDB::SuccessResponse for successes" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 200)

      response = http_handler.handle(request)
      expect(response).to be_an_instance_of(DynamoDB::SuccessResponse)
      expect(response).to be_success
    end

    it "returns a DynamoDB::Response for failures" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 500, body: "Server errors")

      response = http_handler.handle(request)
      expect(response).to be_an_instance_of(DynamoDB::FailureResponse)
      expect(response).not_to be_success
    end

    it "returns a DynamoDB::Response for network errors" do
      error = Errno::ECONNRESET.new
      stub_request(:post, "https://dynamo.local/").to_raise(error)

      response = http_handler.handle(request)
      expect(response).to be_an_instance_of(DynamoDB::FailureResponse)
      expect(response).not_to be_success
      expect(response.error).to eq(error)
      expect(response.body).to be_nil
    end

    it "respects a custom timeout option (set on initialize)" do
      stub_request(:post, "https://dynamo.local/").to_return(status: 200)
      expect_any_instance_of(Net::HTTP::ConnectionPool::Connection).to receive(:read_timeout=).with(5)
      http_handler.handle(request)
    end
  end

  describe "#build_http_request" do
    it "converts a DynamoDB::Request into a Net::HTTP::Post" do
      request = double(DynamoDB::Request,
        uri:      URI("https://dynamo.local/"),
        headers:  {"content-type" => "application/json"},
        body:     "POST body"
      )

      http_handler = DynamoDB::HttpHandler.new
      http_request = http_handler.build_http_request(request)
      expect(http_request).to be_an_instance_of(Net::HTTP::Post)
      expect(http_request.path).to eq("https://dynamo.local/")
      expect(http_request["content-type"]).to eq("application/json")
      expect(http_request.body).to eq("POST body")
    end
  end
end
