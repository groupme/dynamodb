require "spec_helper"

describe DynamoDB::Request do
  let(:uri)         { URI("https://dynamo.host/") }
  let(:credentials) { DynamoDB::Credentials.new("access_key_id", "secret_access_key", "session_token") }
  let(:operation)   { "Query" }
  let(:data)        { {"TableName" => "people", "HashKeyId" => {"N" => "1"}} }
  let(:request) {
    DynamoDB::Request.new(
      uri:         uri,
      credentials: credentials,
      operation:   operation,
      data:        data
    )
  }

  before do
    Time.stub(now: Time.new(2012, 12, 12, 12, 12, 12, "+00:00"))
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

      request.signature.should == signature
    end
  end

  describe "#headers" do
    it "returns as Hash of headers, including AWS security headers" do
      headers = request.headers
      headers.should == {
        "accept"               => "*/*",
        "user-agent"           => "DynamoDB/1.0.0",
        "host"                 => "dynamo.host",
        "content-type"         => "application/x-amz-json-1.0",
        "x-amz-date"           => "Wed, 12 Dec 2012 12:12:12 GMT",
        "x-amz-security-token" => "session_token",
        "x-amz-target"         => "DynamoDB_20111205.Query",
        "x-amzn-authorization" => "AWS3 AWSAccessKeyId=access_key_id,Algorithm=HmacSHA256,Signature=#{request.signature}"
      }
    end
  end

  describe "#body" do
    it "returns the JSON-encoded data" do
      request.body.should == MultiJson.dump(data)
    end
  end
end
