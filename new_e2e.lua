printverbose("your address: "..os.getComputerID())
printverbose("your username:")
local username = io.read()
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

function on_new_comm(comm)
   printverbose("success")
   parallel.waitForAll(
   function()
        while true do 
            printverbose(">")
            local message = io.read()
            comm:send(textutils.serialise({["message"]=message,["user"]=username}))
        end
   end,
   function()
        while true do
            local msg = comm:receive()
            local object = textutils.unserialise(msg)
            if object and object.message then 
                printverbose(object.user..":",object.message)
                printverbose(">")
            end
        end
   end)
end

local encrypted_comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm2.lua")()
printverbose("initiate or receive? [R/i]:")
local char = io.read()
if char:sub(1,1):upper()=="R" then
    printverbose("receiving...")
    local obj = encrypted_comm.receive_until_object_created()
    if obj then
        on_new_comm(obj)
    else 
        printverbose("failed to receive???")
    end
    printverbose("end of receiving")
else
    printverbose("what computer?:")
    local computer = tonumber(io.read())
    printverbose("initiating...")
    local obj = encrypted_comm.initiate(computer)
    if obj then
        on_new_comm(obj)
    else
        printverbose("failed to initiate")
    end
end