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
      Time.stub(:now).and_return(Time.parse("2012-03-24T21:11:02Z"))
      stub_request(:post, "https://sts.amazonaws.com/").
        with(:body => "AWSAccessKeyId=access_key_id&Action=GetSessionToken&Signature=Mna7q/X+GkaDJv7pmfrtIR83rdPKLogbawR2QVMPhxI=&SignatureMethod=HmacSHA256&SignatureVersion=2&Timestamp=2012-03-24T21:11:02Z&Version=2011-06-15").
        to_return(:status => 200, :body => VALID_RESPONSE_BODY)
    end

    it "computes proper signature" do
      sts.signature.should == "Mna7q/X+GkaDJv7pmfrtIR83rdPKLogbawR2QVMPhxI="
    end

    it "returns session_token" do
      sts.session_token.should == "SESSION_TOKEN"
    end
  end
end
