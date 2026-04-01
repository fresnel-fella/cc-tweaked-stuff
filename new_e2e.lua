print("your address: "..os.getComputerID())
print("your username:")
local username = io.read()
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

function on_new_comm(comm)
   print("success")
   parallel.waitForAll(
   function()
        while true do 
            print(">")
            local message = io.read()
            comm:send(textutils.serialise({["message"]=message,["user"]=username}))
        end
   end,
   function()
        while true do
            local msg = comm:receive()
            local object = textutils.unserialise(msg)
            if object and object.message then 
                print(object.user..":",object.message)
                print(">")
            end
        end
   end)
end

local encrypted_comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm2.lua")()
print("initiate or receive? [R/i]:")
local char = io.read()
if char:sub(1,1):upper()=="R" then
    print("receiving...")
    local obj = encrypted_comm.receive_until_object_created()
    if obj then
        on_new_comm(obj)
    else 
        print("failed to receive???")
    end
    print("end of receiving")
else
    print("what computer?:")
    local computer = tonumber(io.read())
    print("initiating...")
    local obj = encrypted_comm.initiate(computer)
    if obj then
        on_new_comm(obj)
    else
        print("failed to initiate")
    end
end