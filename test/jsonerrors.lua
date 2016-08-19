local cjson = require 'cjson'
local inspect = require 'inspect'
local jsonrpc_server = require "resty.jsonrpc_server"
require 'busted.runner'()

-- setup server for testing
local server = jsonrpc_server:new()

local subtract = function(subtrahend, minuend)
        return subtrahend - minuend
end

local update = function(...)
       return nil
end

server:register("subtract", subtract)
server:register("update", update)


-- helper functions to decode json strings and workaround sequence problems.
function test_response(response, expected)
  local reslen, explen = string.len(response), string.len(expected)
  
  -- catch empty responses or expected results
  if ((reslen == 0) or (explen == 0))  then 
     assert.are.equals(response, expected)
  else
     assert.are.equals( inspect(cjson.decode(response)), inspect(cjson.decode(expected)))
  end
end


-- Tests based on the examples at http://www.jsonrpc.org/specification#examples

describe("Test_JSON-RPC2_Compliance", function()
    it("Positional_parameters_test_1", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}]])
        test_response([[{"jsonrpc": "2.0", "result": 19, "id": 1}]], response)
    end)
    
    it("Positional_parameters_test_2", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}]])
        test_response([[{"jsonrpc": "2.0", "result": -19, "id": 2}]], response)
    end)
    
    it("Named_parameters_test_1", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}]])
        test_response([[{"jsonrpc": "2.0", "result": 19, "id": 3}]], response)
    end)
    
    it("Named_parameters_test_2", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}]])
        test_response([[{"jsonrpc": "2.0", "result": 19, "id": 4}]], response)
    end)
    it("Notifications_test_1", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}]])
        test_response([[]], response)
    end)
    
    it("Notifications_test_2", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "foobar"}]])
        test_response([[]], response)
    end)
    
    it("RPC_on_non_existent_method_test", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "foobar", "id": "1"}]])
        test_response([[{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}]], response)
    end)
    it("RPC_with_invalid_json", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]])
        test_response([[{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": "null"}]], response)
    end)
    it("RPC_with_invalid_request_object", function()
        local response = server:execute([[{"jsonrpc": "2.0", "method": 1, "params": "bar"}]])
        test_response([[{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": "null"}]], response)
    end)
end)
