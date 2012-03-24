require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

VALID_RESPONSE_BODY = "<GetSessionTokenResponse " +
"xmlns=\"https://sts.amazonaws.com/doc/2011-06-15/\">
<GetSessionTokenResult>
<Credentials>
<SessionToken>SESSION_TOKEN</SessionToken>
<SecretAccessKey>SECRET_ACCESS_KEY</SecretAccessKey>
<Expiration>2036-03-19T01:03:22.276Z</Expiration>
<AccessKeyId>ACCESS_KEY_ID</AccessKeyId>
</Credentials>
</GetSessionTokenResult>
<ResponseMetadata>
<RequestId>f0fa5827-7156-11e1-8f1e-a92b58fdc66e</RequestId>
</ResponseMetadata>
</GetSessionTokenResponse>
"

module Jedlik
  describe SecurityTokenService do
    let(:sts) { SecurityTokenService.new("access_key_id", "secret_access_key") }

    before do
      Time.stub(:now).and_return(Time.parse("2012-03-24T20:03:36Z"))
      OpenSSL::HMAC.stub!(:digest).and_return("sha256-hash") # base64 => c2hhMjU2LWhhc2g=
      url = "https://sts.amazonaws.com/?AWSAccessKeyId=access_key_id&Action=GetSessionToken&DurationSeconds=3600&Signature=c2hhMjU2LWhhc2g=&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-03-24T20:03:36Z&Version=2011-06-15"
      stub_request(:get, url).to_return(:status => 200, :body => VALID_RESPONSE_BODY)
    end

    it "returns access_key_id" do
      sts.access_key_id.should == "ACCESS_KEY_ID"
    end

    it "returns secret_access_key" do
      sts.secret_access_key.should == "SECRET_ACCESS_KEY"
    end

    it "returns session_token" do
      sts.session_token.should == "SESSION_TOKEN"
    end
  end
end
