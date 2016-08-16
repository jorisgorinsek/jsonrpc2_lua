local zmq = require 'zmq'

function send(request)
  print("\nsend([[" .. request)
  socket:send(request)
  response = socket:recv()
  print("Got:      ".. response)
end

ctx = zmq.init(1)
socket = ctx:socket(zmq.REQ)
socket:connect('tcp://localhost:4568')
  
-- positional parameters
send([[{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}]])
print([[Expected: {"jsonrpc": "2.0", "result": 19, "id": 1}]])

send([[{"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}]])
print([[Expected: {"jsonrpc": "2.0", "result": -19, "id": 2}]])

-- named parameters
send([[{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}]])
print([[Expected: {"jsonrpc": "2.0", "result": 19, "id": 3}]])

send([[{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}]])
print([[Expected: {"jsonrpc": "2.0", "result": 19, "id": 4}]])

-- notifications
send([[{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}]])
send([[{"jsonrpc": "2.0", "method": "foobar"}]])

-- rpc on non existent method
send([[{"jsonrpc": "2.0", "method": "foobar", "id": "1"}]])
print([[Expected: {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}]])

-- rpc call with invalid JSON:
send([[{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]])
print([[Expected: {"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}]])

-- rpc call with invalid Request object:
send([[{"jsonrpc": "2.0", "method": 1, "params": "bar"}]])
print([[Expected: {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}]])
