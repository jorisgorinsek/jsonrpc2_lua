-----------------------------------------------------------------------------
-- JSONRPC4Lua: JSON RPC client calls over http for the Lua language.
-- json.rpc Module. 
-- Author: Craig Mason-Jones
-- Homepage: http://github.com/craigmj/json4lua/
-- Version: 1.0.0
-- This module is released under the MIT License (MIT).
-- Please see LICENCE.txt for details.
--
-- USAGE:
-- This module exposes two functions:
--   proxy( 'url')
--     Returns a proxy object for calling the JSON RPC Service at the given url.
--   call ( 'url', 'method', ...)
--     Calls the JSON RPC server at the given url, invokes the appropriate method, and
--     passes the remaining parameters. Returns the result and the error. If the result is nil, an error
--     should be there (or the system returned a null). If an error is there, the result should be nil.
--
-- REQUIREMENTS:
--  Lua socket 2.0 (http://www.cs.princeton.edu/~diego/professional/luasocket/)
--  json (The JSON4Lua package with which it is bundled)
--  compat-5.1 if using Lua 5.0.
-----------------------------------------------------------------------------

--- @module json.rpc
local rpc = {}     -- Module public namespace

-----------------------------------------------------------------------------
-- Imports and dependencies
-----------------------------------------------------------------------------
local cjson_safe = require("cjson.safe")
local zmq = require 'zmq'

local socketTimeout = 5

-----------------------------------------------------------------------------
-- PUBLIC functions
-----------------------------------------------------------------------------

--- Creates an RPC Proxy object for the given Url of a JSON-RPC server.
-- @param url The URL for the JSON RPC Server.
-- @return Object on which JSON-RPC remote methods can be called.
-- EXAMPLE Usage:
--   local jsolait = json.rpc.proxy('http://jsolait.net/testj.py')
--   print(jsolait.echo('This is a test of the echo method!'))
--   print(jsolait.args2String('first','second','third'))
--   table.foreachi( jsolait.args2Array(5,4,3,2,1), print)
function rpc.proxy(url)
  local serverProxy = {}
  local proxyMeta = {
    __index = function(self, key)
      return function(...)
        return rpc.call(url, key, ...)
      end
    end
  }
  setmetatable(serverProxy, proxyMeta)
  return serverProxy
end

--- Sets connection timeout
-- @param timeout The number of seconds to wait for connection
function rpc.setTimeout(timeout)
	socketTimeout = timeout
end

--- Calls a JSON RPC method on a remote server.
-- Returns a boolean true if the call succeeded, false otherwise.
-- On success, the second returned parameter is the decoded
-- JSON object from the server.
-- On http failure, returns nil and an error message.
-- On success, returns the result and nil.
-- @param url The url of the JSON RPC server.
-- @param method The method being called.
-- @param ... Parameters to pass to the method.
-- @return result, error The JSON RPC result and error. One or the other should be nil. If both
-- are nil, this means that the result of the RPC call was nil.
-- EXAMPLE Usage:
--   print(json.rpc.call('http://jsolait.net/testj.py','echo','This string will be returned'))
function rpc.call(url, method, ...)
  local JSONRequestArray = {
    ["jsonrpc"] = "2.0",
    id=tostring(math.floor(math.random()*32000)),
    ["method"]=method,
    params = {...}
  }
  local response, result , code
  local jsonRequest, err = cjson_safe.encode(JSONRequestArray)
  if jsonRequest == nil then
    return nil, err
  end 
  
  -- for debugging purposes
  print(jsonRequest)
  
  ctx = zmq.init(1)
  socket = ctx:socket(zmq.REQ)
  socket:connect(url)
  
  socket:send(jsonRequest)
  response = socket:recv()
  
  -- Check the response
  if (response == nil) then
    return nil, "ZERMOMQ ERROR! " 
  end
  
  -- for debugging purposes
  print(response)
  
  -- And decode the response check the JSON RPC result code
  result, err = cjson_safe.decode( response )
  if result and result.result then
    return result.result, nil
  else
    if err then
      return nil, err
    else
      if result and result.error then
        return nil, result.error
      else
        return nil, "Unknown error"
      end
    end
  end
end

--- Sendss a JSON RPC notification to a remote server.
-- Returns a boolean true if the call succeeded, false otherwise.
-- On http failure, returns nil and an error message.
-- On success, returns the result and nil.
-- @param url The url of the JSON RPC server.
-- @param method The method being called.
-- @param ... Parameters to pass to the method.
-- @return result, error The JSON RPC result and error. One or the other should be nil. If both
-- are nil, this means that the result of the RPC call was nil.
function rpc.notify(url, method, ...)
--[[
  local JSONRequestArray = {
    ["jsonrpc"] = "2.0",
    ["method"]=method,
    params = {...}
  }
  local result , code
  local jsonRequest, err = cjson_safe.encode(JSONRequestArray)
  if jsonRequest == nil then
    return nil, err
  end 
  
  -- for debugging purposes
  print(jsonRequest)
  
  ctx = zmq.init(1)
  socket = ctx:socket(zmq.PUB)
  
  socket:send(jsonRequest)
  ]]--
end

return rpc
