-- Copyright (c) 2015, rryqszq4
-- All rights reserved.
-- curl -d "{\"method\":\"addition\", \"params\":[1,3]}" http://localhost/lua-jsonrpc-server

local cjson_safe = require "cjson.safe"
local inspect = require 'inspect' -- for debugging purposes

local _M = {
	_VERSION = '0.0.1'
}

local mt = { __index = _M }

function _M.new(self)
	local payload
	local callbacks
	local classes

	payload = nil
	callbacks = {}
	classes = {}
	
	return 
	setmetatable({
		payload = payload,
		callbacks = callbacks,
		classes = classes
	}, mt)
end

function _M.register(self, procedure, closure)
	
	self.callbacks[procedure] = closure 

end

function _M.bind(self, procedure, classname, method)

	self.classes[procedure] = 
	{
		classname = classname,
		method = method
	}

end

function _M.json_format(self, data)
  local err
	self.payload = data

	if type(self.payload) ==  "string" then
		self.payload,err = cjson_safe.decode(self.payload)
		if err then 
		  return false 
		end
	end

	if type(self.payload) == "table" then
		return true
	else
		return false
	end
end

function _M.rpc_format(self)
	if type(self.payload) ~= "table" then
		return {
			-32600, 
			"Invalid Request"
		}
	end

	if self.payload["jsonrpc"] == nil or self.payload["jsonrpc"] ~= "2.0" then
		return {
			-32600,
			"Invalid Request"
		}
	end

  if type(self.payload["method"]) ~= "string" then
    return {
      -32600,
      "Invalid Request"
    }
  end
  
	if self.payload["method"] == nil then
		return {
			-32601,
			"Method not found"
		}
	end

	if self.payload["params"] == nil or type(self.payload["params"]) ~= "table" then
		return {
			-32602,
			"Invalid params"
		}
	end

	return nil
end

function _M.execute_procedure(self, payload_method, payload_params)

	if type(self.callbacks[payload_method]) ~= "nil" then

		return self:execute_callback(payload_method, payload_params)	

	elseif type(self.classes[payload_method]) ~= "nil" then
		
		return self:execute_method(payload_method, payload_params)

	else

		return self:rpc_error(-32601, "Method not found")

	end
	
end

function _M.execute_callback(self, method, params)
	local method = self.callbacks[method]
	local success, result = pcall(method, unpack(params))
	return self:get_response(result)
end

function _M.execute_method(self, method, params)
	
	local classname = self.classes[method]["classname"]
	local method = self.classes[method]["method"]
	local success, result = pcall(classname[method], unpack(params))
	return self:get_response(result)
end

function _M.get_response(self, data)
	local data, err = cjson_safe.encode({
		jsonrpc = "2.0",
		id = self.payload.id,
		result = data
	})
	if data == nil then
	  cjson_safe.encode({
      jsonrpc = "2.0",
      id = self.payload.id,
      error = {code = -32603, message = "Internal error"}
    })
	end
	return data
end

function _M.execute(self, data)
	local result

	result = self:json_format(data)
	if result ~= true then
		return self:rpc_error(-32700, "Parse error")
	end

	result = self:rpc_format()
	if result ~= nil then
		return self:rpc_error(result[1], result[2])
	end

	return self:execute_procedure(self.payload.method, self.payload.params)

end

function _M.rpc_error(self, code, message)
  local id = "null"
  if self.payload ~= nil then
    if self.payload.id ~= nil then
      id = self.payload.id
    end
  end
   
	local data, err = cjson_safe.encode({
		jsonrpc = "2.0",
		id = id,
		error = {
			code = code,
			message = message
		}
	})
  if data == nil then
    cjson_safe.encode({
      jsonrpc = "2.0",
      id = id,
      error = {
        code = -32603, 
        message = "Internal error"
      }
    })
  end
	return data
end

return _M

