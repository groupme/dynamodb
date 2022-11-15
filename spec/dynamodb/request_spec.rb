require "spec_helper"

describe DynamoDB::Request do
  it "signs the request" do
    allow(Time).to receive_messages(now: Time.parse("20130508T201304Z"))

    uri = URI("https://dynamodb.us-east-1.amazonaws.com/")
    signer = AWS4::Signer.new(
      access_key: "access_key_id",
      secret_key: "secret_access_key",
      region: "us-east-1"
    )
    request = DynamoDB::Request.new(
      uri: uri,
      signer: signer,
      body: {},
      operation: "DynamoDB_20111205.ListTables",
    )

    expect(request.headers).to eq({
      "Content-Type"=>"application/x-amz-json-1.0",
      "Content-Length"=>"2",
      "Date"=>"Wed, 08 May 2013 20:13:04 GMT",
      "User-Agent"=>"groupme/dynamodb",
      "Host"=>"dynamodb.us-east-1.amazonaws.com",
      "X-AMZ-Target"=>"DynamoDB_20111205.ListTables",
      "X-AMZ-Date"=>"20130508T201304Z",
      "X-AMZ-Content-SHA256"=>"44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
      "Authorization"=>"AWS4-HMAC-SHA256 Credential=access_key_id/20130508/us-east-1/dynamodb/aws4_request, SignedHeaders=content-length;content-type;date;host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-target, Signature=9e551627237673b4deaa2c22fd3b3777d6d0705facd35b56b289e357c4995c46"
    })
  end
end
