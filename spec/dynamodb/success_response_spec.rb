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
      stub = stub_request(:post, "https://dynamodb.local").
        to_return(status: 201, body: MultiJson.dump(body))
      response = DynamoDB::SuccessResponse.new(stub.response)
      expect(response.hash_key_element).to eq(1)
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
      stub = stub_request(:post, "https://dynamodb.local").
        to_return(status: 201, body: MultiJson.dump(body))
      response = DynamoDB::SuccessResponse.new(stub.response)
      expect(response.range_key_element).to eq(1501)
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
            "person_id"  => {"N" => "1501"},
            "pinned_at"  => {"NULL" => true}
          }
        ],
        "Count" => 1,
        "ConsumedCapacityUnits" => 0.5
      }
      stub = stub_request(:post, "https://dynamodb.local").
        to_return(status: 201, body: MultiJson.dump(body))

      response = DynamoDB::SuccessResponse.new(stub.response)
      expect(response.items[0]["name"]).to eq("John Smith")
      expect(response.items[0]["created_at"]).to eq(1321564309.99428)
      expect(response.items[0]["disabled"]).to eq(0)
      expect(response.items[0]["group_id"]).to eq(1)
      expect(response.items[0]["person_id"]).to eq(1500)

      expect(response.items[1]["name"]).to eq("Jane Smith")
      expect(response.items[1]["created_at"]).to eq(1321564309.99428)
      expect(response.items[1]["disabled"]).to eq(1)
      expect(response.items[1]["group_id"]).to eq(1)
      expect(response.items[1]["person_id"]).to eq(1501)
    end
  end

  it "returns type-casted entries from Responses keys" do
    body = {
      "Responses" => {
        "table_name" => [
          {
            "text" => { "S" => "hi" },
            "message_id" => { "N" => "1000" },
            "like_user_ids" => { "SS" => ["1", "2"] }
          },
          {
            "text" => { "S" => "hello" },
            "message_id" => { "N" => "2000" },
            "like_user_ids" => { "SS" => ["3", "4"] }
          }
        ],
        "other_table_name" => [
          {
            "text" => { "S" => "goodbye"}
          }
        ]
      }
    }

    stub = stub_request(:post, "https://dynamodb.local").
      to_return(status: 201, body: MultiJson.dump(body))

    response = DynamoDB::SuccessResponse.new(stub.response)

    expect(response.responses["table_name"][0]["text"]).to eq("hi")
    expect(response.responses["table_name"][0]["message_id"]).to eq(1000)
    expect(response.responses["table_name"][0]["like_user_ids"]).to eq(["1", "2"])

    expect(response.responses["table_name"][1]["text"]).to eq("hello")
    expect(response.responses["table_name"][1]["message_id"]).to eq(2000)
    expect(response.responses["table_name"][1]["like_user_ids"]).to eq(["3", "4"])

    expect(response.responses["other_table_name"][0]["text"]).to eq("goodbye")
  end

  describe "#item" do
    it "returns the type-casted 'Item' key" do
      body = {
        "Item"=> {
          "name"       => {"S" => "John Smith"},
          "created_at" => {"N" => "1321564309.99428"},
          "disabled"   => {"N" => "0"},
          "group_id"   => {"N" => "1"},
          "person_id"  => {"N" => "1500"},
          "pinned_at"  => {"NULL" => true}
        },
        "ConsumedCapacityUnits" => 0.5
      }
      stub = stub_request(:post, "https://dynamodb.local").
        to_return(status: 201, body: MultiJson.dump(body))


      response = DynamoDB::SuccessResponse.new(stub.response)
      expect(response.item["name"]).to eq("John Smith")
      expect(response.item["created_at"]).to eq(1321564309.99428)
      expect(response.item["disabled"]).to eq(0)
      expect(response.item["group_id"]).to eq(1)
      expect(response.item["person_id"]).to eq(1500)
      expect(response.item["pinned_at"]).to be_nil
    end
  end
end
