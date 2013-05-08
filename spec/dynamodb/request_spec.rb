require "spec_helper"

describe DynamoDB::Request do
  let(:uri)         { URI("https://dynamodb.us-east-1.amazonaws.com/") }
  let(:credentials) { DynamoDB::Credentials.new("access_key_id", "secret_access_key") }
  let(:data)        { {} }
  let(:request) {
    DynamoDB::Request.new(
      uri:          uri,
      api_version:  "DynamoDB_20111205",
      credentials:  credentials,
      data:         data,
      operation:    "ListTables",
    )
  }

  it "signs the request" do
    Time.stub(now: Time.parse("20130508T201304Z"))

    request.headers.should == {
      "content-type"=>"application/x-amz-json-1.0",
      "x-amz-target"=>"DynamoDB_20111205.ListTables",
      "content-length"=>2,
      "user-agent"=>"DynamoDB/#{DynamoDB::VERSION}",
      "host"=>"dynamodb.us-east-1.amazonaws.com",
      "x-amz-date"=>"20130508T201304Z",
      "x-amz-content-sha256"=>"44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
      "authorization"=>"AWS4-HMAC-SHA256 Credential=access_key_id/20130508/us-east-1/dynamodb/aws4_request, SignedHeaders=content-length;content-type;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target, Signature=0ca052a91421f5bf54b64ca4f4f5f6aef059b4f414e0c2543a65ff13d298fb42"
    }
  end
end
