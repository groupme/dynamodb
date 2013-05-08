require 'spec_helper'

describe DynamoDB::Connection do
  describe "#post" do
    let(:connection) { DynamoDB::Connection.new(:access_key_id => "id", :secret_access_key => "secret") }

    it "signs and posts a request" do
      stub_request(:post, "https://dynamodb.us-east-1.amazonaws.com/").
        to_return(status: 200, body: MultiJson.encode({"TableNames" => ["example"]}))
      result = connection.post :ListTables
      result.data.should == {"TableNames" => ["example"]}
    end

    it "creates a SuccessResponse when 200" do
      stub_request(:post, "https://dynamodb.us-east-1.amazonaws.com/").
        to_return(status: 200, body: "")
      result = connection.post :ListTables
      result.should be_a_kind_of(DynamoDB::SuccessResponse)
    end

    it "creates a FailureResponse when 400" do
      stub_request(:post, "https://dynamodb.us-east-1.amazonaws.com/").
        to_return(status: 400, body: "")
      result = connection.post :ListTables
      result.should be_a_kind_of(DynamoDB::FailureResponse)
    end
  end
end
