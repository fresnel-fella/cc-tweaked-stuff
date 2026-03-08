function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

local netpoll = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/netpoll.lua")
local poll_obj = netpoll.new()
local comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm.lua")
comm.on_new_comm = function(comm_obj)
    print("something happened yay")
    print("their pub key is "..comm_obj.their_pub_key:toString())
end

print("generating keys...")
local private,public = comm.crypt.generate_asy_keys()
comm.our_pri_key = private
comm.our_pub_key = public

local modem = peripheral.find("modem",rednet.open)
print("your address: "..modem.getNameLocal())
io.write("\nenter address of computer:")
local address = read()
io.write("\n")
print("searching...")
comm.initiate_with(address)

function process(addr,msg,prot)
    comm.filter(addr,msg,prot)
end

while true do
    os.sleep(0.1)
    poll_obj:poll()
    poll_obj:process(process)
end