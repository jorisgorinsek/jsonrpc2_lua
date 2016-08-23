local jsonrpc_server = require "resty.jsonrpc_server"
local jsonrpc_demo = require "resty.jsonrpc_demo"
local zmq = require 'zmq'

local server = jsonrpc_server:new()

local add1 = function(a, b)
        print([[calling add1 in testServer]])
        return a + b
end

local subtract = function(subtrahend, minuend)
        return subtrahend - minuend
end

local update = function(...)
       return nil
end

local register = server:register([[addition]], add1)
local binder = server:bind([[addition1]], jsonrpc_demo, [[add1]])
server:register("subtract", subtract)
server:register("update", update)


ctx = zmq.init(1)
socket = ctx:socket(zmq.REP)
socket:bind 'tcp://*:4568'

while(true) do
  local data = socket:recv()
  local result = server:execute(data)
  socket:send(result)
end