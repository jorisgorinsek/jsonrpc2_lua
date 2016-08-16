local _M = {}

local mt = { __index = _M }

function _M.new (self) 
    return setmetatable({ }, mt)
end

function _M.add1(a, b)
  print("calling add1 in resty.jsonrpc_demo")
	return a+b+1
end

return _M