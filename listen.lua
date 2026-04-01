function listen()
    local new_count = count + 1
    while true do
        os.sleep(0)
        if count >= new_count then
            return id,msg,prot
        end
    end
end
local id,msg,prot = nil,nil,nil
local count = 0

return function(listen_holder,main)
    listen_holder[1] = listen
    parallel.waitForAll(main,function()
        while true do
            id,msg,prot = rednet.receive()
            count = count + 1
        end
    end)
end