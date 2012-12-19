require 'spec_helper'

describe DynamoDB::SuccessResponse do
  describe "#hash_key_element" do
    it "returns the typecast value of HashKeyElement" do
      body = {
        "LastEvaluatedKey" => {
          "HashKeyElement"  => {"N" => "1"},
          "RangeKeyElement" => {"N" => "1501"}
        }
      }
      http_response = stub(Net::HTTPResponse, body: MultiJson.dump(body))
      response = DynamoDB::SuccessResponse.new(http_response)
      response.hash_key_element.should == 1
    end
  end

  describe "#range_key_element" do
    it "returns the typecast value of RangeKeyElement" do
      body = {
        "LastEvaluatedKey" => {
          "HashKeyElement"  => {"N" => "1"},
          "RangeKeyElement" => {"N" => "1501"}
        }
      }
      http_response = stub(Net::HTTPResponse, body: MultiJson.dump(body))
      response = DynamoDB::SuccessResponse.new(http_response)
      response.range_key_element.should == 1501
    end
  end

  describe "#items" do
    it "returns type-casted entries from the 'Items' key" do
      body = {
        "Items" => [
          {
            "name"       => {"S" => "John Smith"},
            "created_at" => {"N" => "1321564309.99428"},
            "disabled"   => {"N" => "0"},
            "group_id"   => {"N" => "1"},
            "person_id"  => {"N" => "1500"}
          },
          {
            "name"       => {"S" => "Jane Smith"},
            "created_at" => {"N" => "1321564309.99428"},
            "disabled"   => {"N" => "1"},
            "group_id"   => {"N" => "1"},
            "person_id"  => {"N" => "1501"}
          }
        ],
        "Count" => 1,
        "ConsumedCapacityUnits" => 0.5
      }
      http_response = stub(Net::HTTPResponse, body: MultiJson.dump(body))

      response = DynamoDB::SuccessResponse.new(http_response)
      response.items[0]["name"].should == "John Smith"
      response.items[0]["created_at"].should == 1321564309.99428
      response.items[0]["disabled"].should == 0
      response.items[0]["group_id"].should == 1
      response.items[0]["person_id"].should == 1500

      response.items[1]["name"].should == "Jane Smith"
      response.items[1]["created_at"].should == 1321564309.99428
      response.items[1]["disabled"].should == 1
      response.items[1]["group_id"].should == 1
      response.items[1]["person_id"].should == 1501
    end
  end

  describe "#item" do
    it "returns the type-casted 'Item' key" do
      body = {
        "Item"=> {
          "name"       => {"S" => "John Smith"},
          "created_at" => {"N" => "1321564309.99428"},
          "disabled"   => {"N" => "0"},
          "group_id"   => {"N" => "1"},
          "person_id"  => {"N" => "1500"}
        },
        "ConsumedCapacityUnits" => 0.5
      }
      http_response = stub(Net::HTTPResponse, body: MultiJson.dump(body))

      response = DynamoDB::SuccessResponse.new(http_response)
      response.item["name"].should == "John Smith"
      response.item["created_at"].should == 1321564309.99428
      response.item["disabled"].should == 0
      response.item["group_id"].should == 1
      response.item["person_id"].should == 1500
    end
  end
end
