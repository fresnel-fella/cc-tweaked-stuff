function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

local netpoll = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/netpoll.lua")()
local poll_obj = netpoll.new()
poll_obj.start(poll_obj,function()
    local comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm.lua")()
    comm.on_new_comm = function(comm_obj)
        print("something happened yay")
        print("their pub key is "..tostring(comm_obj.their_pub_key[1]),tostring(comm_obj.their_pub_key[2]))
        parallel.waitForAll(function() 
            while true do
                print("send a message:")
                local message = io.read()
                print(message)
                comm_obj:send_encrypted({["message"] = message})
            end
        end,function() 
            while true do 
                local recieved = comm_obj:receive()
                print(recieved)
                print("user:",recieved.message)
            end
        end)
    end

    print("generating keys...")
    local private,public = comm.crypt.generate_asy_keys()
    comm.our_pri_key = private
    comm.our_pub_key = public
    print("private:",private)
    print("public:",public)

    peripheral.find("modem",rednet.open)
    local modem = peripheral.find("modem")
    print("your address: "..os.getComputerID())
    io.write("\nenter address of computer:")
    local address = io.read()
    io.write("\n")
    print("searching...")
    comm.initiate_with(tonumber(address))

    function process(addr,msg,prot)
        print("processing")
        comm.filter(addr,msg,prot)
    end
    while true do
        os.sleep(0.1)
        poll_obj:process(process)
    end
end)