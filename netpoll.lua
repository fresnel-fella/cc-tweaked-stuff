local netpoll = {}
netpoll.__index = netpoll
function netpoll.new()
    local self = {}
    setmetatable(self,netpoll)
    self.reci_requests = {}
    self.send_requests = {}
    return self
end

function netpoll:poll()
    local stop = false
    repeat
        local id,msg,prot = rednet.receive()
        if not msg then stop = true else
            table.insert(self.reci_requests,{id,msg,prot})
        end
    until stop
end

function netpoll:process(func)
    for i, req in pairs(self.reci_requests) do
        func(req[1],req[2],req[3])
        self.reci_requests[i] = nil
    end
end

return netpoll