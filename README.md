DynamoDB
========

Communicate with [Amazon DynamoDB](http://aws.amazon.com/dynamodb/) from Ruby.

This is a lightweight alternative to the official Amazon AWS gem.

The goal of this library is to be a high performance driver, not an ORM.

Usage
-----

The API maps the DynamoDB API closely. Once the connection object is ready, all
requests are done through `#post`. The first argument is the name of the
operation, the second is a hash that will be converted to JSON and used as the
request body.

Responses come back as `SuccessResponse` or `FailureResponse` objects.

    require 'dynamodb'

    > conn = DynamoDB::Connection.new(access_key_id: 'ACCESS_KEY', secret_access_key: 'SECRET_KEY')
     => #<DynamoDB::Connection:...>

    > response = conn.post(:ListTables)
     => #<DynamoDB::SuccessResponse:...>

    > response.data
     => {"TableNames"=>["my-dynamo-table"]}

For operations that return `Item` or `Items` keys, there are friendly accessors
on the responses that also cast the values into strings and numbers:

    > response = conn.post(:GetItem, {:TableName => "my-dynamo-table", :Key => {:S => "some-key"}})
     => #<DynamoDB::SuccessResponse:...>

    > response.item
     => {"text"=>"Hey there"}

    > response = conn.post(:Query, {...})
     => #<DynamoDB::SuccessResponse:...>

    > response.items
     => [{...}]

TODO
----

* Implement Signature Version 4

Credits
-------

This project started as a fork of [Jedlik](https://github.com/hashmal/jedlik)
by [Jérémy Pinat](https://github.com/hashmal) but has significantly diverged.

License
-------

Copyright (c) 2011-2012 GroupMe, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
