require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Jedlik
  describe SecurityTokenService do
    let(:sts) { SecurityTokenService.new("access_key_id", "secret_access_key") }

    context "success" do
      before do
        Time.stub(:now).and_return(Time.parse("2012-03-24T22:10:38Z"))
        success_body = <<-XML
          <GetSessionTokenResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
          <GetSessionTokenResult>
          <Credentials>
          <SessionToken>session_token</SessionToken>
          <SecretAccessKey>secret_access_key</SecretAccessKey>
          <Expiration>2036-03-19T01:03:22.276Z</Expiration>
          <AccessKeyId>access_key_id</AccessKeyId>
          </Credentials>
          </GetSessionTokenResult>
          <ResponseMetadata>
          <RequestId>f0fa5827-7156-11e1-8f1e-a92b58fdc66e</RequestId>
          </ResponseMetadata>
          </GetSessionTokenResponse>
        XML

        stub_request(:get, "https://sts.amazonaws.com/").
          with(:query => {
            "AWSAccessKeyId"   => "access_key_id",
            "Action"           => "GetSessionToken",
            "Signature"        => "mh6OAPPjI2GC5B8YBVC9n1V/SV4EHTWWR+4h7QjYrgo=",
            "SignatureMethod"  => "HmacSHA256",
            "SignatureVersion" => "2",
            "Timestamp"        => "2012-03-24T22:10:38Z",
            "Version"          => "2011-06-15",
            "DurationSeconds"  => "129600"
          }).to_return(:status => 200, :body => success_body)
      end

      it "obtains session_token, access_key_id, secret_access_key" do
        sts = SecurityTokenService.new("access_key_id", "secret_access_key")
        sts.access_key_id.should == "access_key_id"
        sts.secret_access_key.should == "secret_access_key"
        sts.session_token.should == "session_token"
      end
    end

    context "failure" do
      before do
        Time.stub(:now).and_return(Time.parse("2012-03-24T22:10:38Z"))
        error_body = <<-XML
          <ErrorResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/">
            <Error>
              <Type>Sender</Type>
              <Code>InvalidClientTokenId</Code>
              <Message>The security token included in the request is invalid</Message>
            </Error>
            <RequestId>a9f51cd0-7f5b-11e1-8022-bd0f2fc51c4b</RequestId>
          </ErrorResponse>
        XML

        stub_request(:get, "https://sts.amazonaws.com/").
          with(:query => {
            "AWSAccessKeyId"   => "access_key_id",
            "Action"           => "GetSessionToken",
            "Signature"        => "mh6OAPPjI2GC5B8YBVC9n1V/SV4EHTWWR+4h7QjYrgo=",
            "SignatureMethod"  => "HmacSHA256",
            "SignatureVersion" => "2",
            "Timestamp"        => "2012-03-24T22:10:38Z",
            "Version"          => "2011-06-15",
            "DurationSeconds"  => "129600"
          }).to_return(:status => 403, :body => error_body)
      end

      it "raises an AuthenticationError" do
        s = SecurityTokenService.new("access_key_id", "secret_access_key")
        proc {
          s.session_token
        }.should raise_error(Jedlik::AuthenticationError)
      end
    end
  end
end
