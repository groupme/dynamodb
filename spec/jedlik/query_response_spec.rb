require 'spec_helper'

describe Jedlik::QueryResponse do
  before do
    body = {
      "LastEvaluatedKey" => {
        "HashKeyElement" => {"N"=>"1"},
        "RangeKeyElement"=>{"N"=>"1501"}
      },
      "Items"=>[
        {
          "name"=>{"S"=>"John Smith"},
          "created_at"=>{"N"=>"1321564309.99428"},
          "disabled"=>{"N"=>"0"},
          "group_id"=>{"N"=>"1"},
          "person_id"=>{"N" => "1500"}
        },
        {
          "name"=>{"S"=>"Jane Smith"},
          "created_at"=>{"N"=>"1321564309.99428"},
          "disabled"=>{"N"=>"1"},
          "group_id"=>{"N"=>"1"},
          "person_id"=>{"N" => "1501"}
        }
      ],
      "Count" => 1,
      "ConsumedCapacityUnits" => 0.5
    }
    @typhoeus_response = mock("response", :body => Yajl::Encoder.encode(body))
  end

  describe "#hash_key_element" do
    it "returns the typecast value of HashKeyElement" do
      response = Jedlik::QueryResponse.new(@typhoeus_response)
      response.hash_key_element.should == 1
    end
  end

  describe "#range_key_element" do
    it "returns the typecast value of RangeKeyElement" do
      response = Jedlik::QueryResponse.new(@typhoeus_response)
      response.range_key_element.should == 1501
    end
  end

  it "type casts response" do
    response = Jedlik::QueryResponse.new(@typhoeus_response)
    response[0]["name"].should == "John Smith"
    response[0]["created_at"].should == 1321564309.99428
    response[0]["disabled"].should == 0
    response[0]["group_id"].should == 1
    response[0]["person_id"].should == 1500

    response[1]["name"].should == "Jane Smith"
    response[1]["created_at"].should == 1321564309.99428
    response[1]["disabled"].should == 1
    response[1]["group_id"].should == 1
    response[1]["person_id"].should == 1501
  end

  describe "enumerable" do
    it "behaves like an enumerable for Items" do
      response = Jedlik::QueryResponse.new(@typhoeus_response)
      response.map {|person| person["name"] }.should == ["John Smith", "Jane Smith"]
    end
  end
end
