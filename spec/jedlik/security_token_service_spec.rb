require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

VALID_RESPONSE_BODY = "<GetSessionTokenResponse " +
"xmlns=\"https://sts.amazonaws.com/doc/2011-06-15/\">
<GetSessionTokenResult>
<Credentials>
<SessionToken>SESSION_TOKEN</SessionToken>
<SecretAccessKey>secret_access_key</SecretAccessKey>
<Expiration>2036-03-19T01:03:22.276Z</Expiration>
<AccessKeyId>access_key_id</AccessKeyId>
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
      Time.stub(:now).and_return(Time.parse("2012-03-24T22:10:38Z"))
      stub_request(:post, "https://sts.amazonaws.com/").
        with(:body => "AWSAccessKeyId=access_key_id&Action=GetSessionToken&Signature=ybtIr0mrJ28uJFYMMNi+bLANvIDD7tAh6F97JGgtvDw=&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-03-24T22:10:38Z&Version=2011-06-15").
        to_return(:status => 200, :body => VALID_RESPONSE_BODY)
    end

    it "computes proper signature" do
      s = SecurityTokenService.new("access_key_id", "secret_access_key")
      s.string_to_sign.should == [
        "POST",
        "sts.amazonaws.com",
        "/",
        "AWSAccessKeyId=access_key_id&Action=GetSessionToken&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-03-24T22%3A10%3A38Z&Version=2011-06-15"
      ].join("\n")
      s.signature.should == "ybtIr0mrJ28uJFYMMNi+bLANvIDD7tAh6F97JGgtvDw="
    end

    it "returns session_token" do
      sts.session_token.should == "SESSION_TOKEN"
    end
  end
end
