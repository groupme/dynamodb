require "spec_helper"

describe DynamoDB::FailureResponse do
  describe "#error" do
    it "returns a ClientError if the HTTP response code is between 400 and 499" do
      http_response = stub("Response", code: "401", message: "Not authorized", body: "Error details")
      response = DynamoDB::FailureResponse.new(http_response)
      response.error.should be_an_instance_of(DynamoDB::ClientError)
      response.error.message.should == "401: Not authorized"
      response.body.should == "Error details"
    end

    it "returns a ServerError if the HTTP response code is between 500 and 599" do
      http_response = stub("Response", code: "500", message: "Internal server error", body: "")
      response = DynamoDB::FailureResponse.new(http_response)
      response.error.should be_an_instance_of(DynamoDB::ServerError)
      response.error.message.should == "500: Internal server error"
    end

    it "returns a ServerError otherwise" do
      http_response = stub("Response", code: "0", message: "")
      response = DynamoDB::FailureResponse.new(http_response)
      response.error.should be_an_instance_of(DynamoDB::ServerError)
      response.error.message.should == "0: "
    end
  end
end
