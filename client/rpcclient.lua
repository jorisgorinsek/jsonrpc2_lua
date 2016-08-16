
-- this example will work only if cgilua module has this fix https://github.com/pdxmeshnet/cgilua/commit/1b35d812c7d637b91f2ac0a8d91f9698ba84d8d9

local rpc = require("json.rpc")

server = rpc.proxy('tcp://localhost:4568')

--[[ 
result, error = server.echo("foo bar")
if error then
  print(error)
else
  print(result)
end

result, error = server.subtract(42, 23)
if error then
  print(error)
else
  --table.foreach(result, print)
  print(result)
end
]]--

result, error = server.addition1(42, 23)
if error then
  print("Error code: " .. error.code .. ", " .. error.message)
else
  --table.foreach(result, print)
  print(result)
end