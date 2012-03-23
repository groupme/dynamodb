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
    let(:sts){SecurityTokenService.new "access_key_id", "secret_access_key"}
    let(:response){(Typhoeus::Response.new body: VALID_RESPONSE_BODY)}

    before{Typhoeus::Request.stub(:get).and_return response}

    shared_examples_for 'cached' do |method|
      it 'sends a request to Amazon STS at first call' do
        Typhoeus::Request.should_receive(:get).and_return response
        sts.send method
      end

      it 'signs the request'

      it 'caches its value' do
        Typhoeus::Request.should_receive(:get).and_return response
        sts.send method
        sts.send method
      end
    end

    describe 'access_key_id' do
      it_behaves_like 'cached', :access_key_id

      it 'returns a value' do
        sts.access_key_id.should == "ACCESS_KEY_ID"
      end
    end

    describe 'secret_access_key' do
      it_behaves_like 'cached', :secret_access_key

      it 'returns a value' do
        sts.secret_access_key.should == "SECRET_ACCESS_KEY"
      end
    end

    describe 'session_token' do
      it_behaves_like 'cached', :session_token

      it 'returns a value' do
        sts.session_token.should == "SESSION_TOKEN"
      end
    end
  end
end
