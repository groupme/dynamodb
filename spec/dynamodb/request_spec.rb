require "spec_helper"

describe DynamoDB::Request do
  let(:uri)         { URI("https://dynamo.host/") }
  let(:credentials) { DynamoDB::Credentials.new("access_key_id", "secret_access_key", "session_token") }
  let(:operation)   { "Query" }
  let(:data)        { {"TableName" => "people", "HashKeyId" => {"N" => "1"}} }

  before do
    Time.stub(now: Time.new(2012, 12, 12, 12, 12, 12, "+00:00"))
  end

  describe "#http_request" do
    it "crafts an unsigned Net::HTTP request" do
      request = DynamoDB::Request.new(uri, credentials, operation, data)
      http_request = request.http_request
      http_request.should be_an_instance_of(Net::HTTP::Post)
      http_request.path.should == uri.to_s
      http_request.body.should == MultiJson.dump(data)

      http_request["accept"].should == "*/*"
      http_request["user-agent"].should == "DynamoDB/1.0.0"
      http_request["host"].should == "dynamo.host"
      http_request["content-type"].should == "application/x-amz-json-1.0"
      http_request["x-amz-date"].should == "Wed, 12 Dec 2012 12:12:12 GMT"
      http_request["x-amz-security-token"].should == "session_token"
      http_request["x-amz-target"].should == "DynamoDB_20111205.Query"
    end
  end

  describe "#signature" do
    it "returns the AWS authorization signature" do
      amazon_header_string = [
        "x-amz-date:Wed, 12 Dec 2012 12:12:12 GMT\n",
        "x-amz-security-token:session_token\n",
        "x-amz-target:DynamoDB_20111205.Query\n"
      ].join

      body = MultiJson.dump(data)
      signing_string = "POST\n/\n\nhost:dynamo.host\n#{amazon_header_string}\n#{body}"
      signature = DynamoDB::Request.digest(signing_string, "secret_access_key")

      request = DynamoDB::Request.new(uri, credentials, operation, data)
      request.signature.should == signature
    end
  end

  describe "#signed_http_request" do
    it "signs the HTTP request with a session token from the AWS Security Token Service" do
      request = DynamoDB::Request.new(uri, credentials, operation, data)
      signature = request.signature
      signed_http_request = request.signed_http_request
      signed_http_request["x-amzn-authorization"] = "AWS3 AWSAccessKeyId=access_key_id,Algorithm=HmacSHA256,Signature=#{signature}"
    end
  end

  describe "#response" do
    let(:request) { DynamoDB::Request.new(uri, credentials, operation, data) }

    context "when the request succeeds" do
      it "returns a response with a body" do
        stub_request(:post, uri.to_s).to_return(status: 200, body: "{}", headers: {})
        response = request.response
        response.body.should == "{}"
      end
    end

    context "when a server error occurs" do
      it "raises a DynamoDB::ServerError" do
        stub_request(:post, uri.to_s).to_return(status: 500, body: "Failed for some reason")
        expect { request.response }.to raise_error(DynamoDB::ServerError)
      end
    end

    context "when the connection fails" do
      it "raises a DynamoDB::ServerError" do
        stub_request(:post, uri.to_s).to_return(status: 0, body: "")
        expect { request.response }.to raise_error(DynamoDB::ServerError)
      end
    end

    context "when the connection times out" do
      it "raises a DynamoDB::TimeoutError" do
        stub_request(:post, uri.to_s).to_timeout
        expect { request.response }.to raise_error(DynamoDB::TimeoutError)
      end
    end
  end
end
