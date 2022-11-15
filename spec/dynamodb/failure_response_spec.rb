require "spec_helper"

describe DynamoDB::FailureResponse do
  describe "#error" do
    it "returns a ClientError if the HTTP response code is between 400 and 499" do
      http_response = double("Response", code: "401", message: "Not authorized", body: "Error details")
      response = DynamoDB::FailureResponse.new(http_response)
      expect(response.error).to be_an_instance_of(DynamoDB::ClientError)
      expect(response.error.message).to eq("401: Not authorized")
      expect(response.body).to eq("Error details")
    end

    it "returns a ServerError if the HTTP response code is between 500 and 599" do
      http_response = double("Response", code: "500", message: "Internal server error", body: "")
      response = DynamoDB::FailureResponse.new(http_response)
      expect(response.error).to be_an_instance_of(DynamoDB::ServerError)
      expect(response.error.message).to eq("500: Internal server error")
    end

    it "returns a ServerError otherwise" do
      http_response = double("Response", code: "0", message: "")
      response = DynamoDB::FailureResponse.new(http_response)
      expect(response.error).to be_an_instance_of(DynamoDB::ServerError)
      expect(response.error.message).to eq("0: ")
    end
  end
end
