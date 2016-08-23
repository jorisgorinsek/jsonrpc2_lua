server {
    location /lua-jsonrpc-server {
        default_type "application/json";

        content_by_lua '
            local jsonrpc_server = require "resty.jsonrpc_server"
            local jsonrpc_demo = require "resty.jsonrpc_demo"

            local server = jsonrpc_server:new()

            local add1 = function(a, b)
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

            ngx.req.read_body()
            local data = ngx.var.request_body
            local result = server:execute(data)

            ngx.say(result);

        ';
    }
}
