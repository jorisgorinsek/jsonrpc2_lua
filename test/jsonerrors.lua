local zmq = require 'zmq'
local cjson = require 'cjson'
local inspect = require 'inspect'

succeeded = 0
failed = 0

function compare(tb1, tb2)
  local response = inspect(tb1)
  local expected = inspect(tb2)
  if response ~= expected then
    return false
  end
  return true
end

function test_response(response, expected, test)
  local reslen, explen = string.len(response), string.len(expected)
  
  -- catch empty responses or expected results
  if ((reslen == 0) and (explen ~= 0)) or 
      (reslen ~= 0) and (explen == 0) then 
      print(test .. " failed.")
      failed =  failed + 1 
      return false
  elseif (reslen == 0) and (explen ~= 0) then
      print(test .. " succeeded.")
      succeeded = succeeded + 1
      return true
  end
  
  if compare(cjson.decode(response), cjson.decode(expected)) == true then
    print(test .. " succeeded.")
    succeeded = succeeded + 1
    return true
  else
    print(test .. " failed.")
    failed =  failed + 1
    return false
  end
end

function send(request)
  socket:send(request)
  local response = socket:recv()
  return response
end

-- connect to server
ctx = zmq.init(1)
socket = ctx:socket(zmq.REQ)
socket:connect('tcp://localhost:4568')


--TODO; integrate these in busted

local response, expected
  
-- positional parameters
response = send([[{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}]])
expected = [[{"jsonrpc": "2.0", "result": 19, "id": 1}]]
test_response(response, expected, [[positional parameters test 1]])


response = send([[{"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}]])
expected = [[{"jsonrpc": "2.0", "result": -19, "id": 2}]]
test_response(response, expected, [[positional parameters test 2]])

-- named parameters
response = send([[{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}]])
expected = [[{"jsonrpc": "2.0", "result": 19, "id": 3}]]
test_response(response, expected, [[named parameters test 1]])

response = send([[{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}]])
expected = [[{"jsonrpc": "2.0", "result": 19, "id": 4}]]
test_response(response, expected, [[named parameters test 2]])

-- notifications
response = send([[{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}]])
expected = [[]]
test_response(response, expected, [[notifications test 1]])

response = send([[{"jsonrpc": "2.0", "method": "foobar"}]])
expected = [[]]
test_response(response, expected, [[notifications test 2]])

-- rpc on non existent method
response = send([[{"jsonrpc": "2.0", "method": "foobar", "id": "1"}]])
expected = [[{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}]]
test_response(response, expected, [[rpc on non existent method test 1]])

-- rpc call with invalid JSON:
response = send([[{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]])
expected = [[{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": "null"}]]
test_response(response, expected, [[rpc call with invalid JSON]])

-- rpc call with invalid Request object:
response = send([[{"jsonrpc": "2.0", "method": 1, "params": "bar"}]])
expected = [[{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": "null"}]]
test_response(response, expected, [[rpc call with invalid Request object]])

local total = failed + succeeded
print(succeeded.."/"..total.." tests succeeded, "..failed.."/"..total.." tests failed.")