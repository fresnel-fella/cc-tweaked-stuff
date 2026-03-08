local comm = {}
comm.__index = comm
comm.our_pub_key = nil
comm.our_pri_key = nil
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
local crypt = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/crypt.lua")
comm.crypt = crypt
local prot = "crypt_comm"
local init_prot = "init_comm"
function comm.on_new_comm(comm_obj) end
function comm._new()
    local self = {}
    setmetatable(self,comm)
    return self
end

local phases = {}

function cancel(address)
    phases[address] = nil
    phases[comms] = nil
end

function comm.initiate_with(address)
    rednet.send(address,our_pub_key,init_prot)
    addresses[address] = true
end

local addresses = {}

function comm.filter(address,msg,prot)
    if prot ~= init_prot then return end
    if not our_pub_key or not our_pri_key then return end
    local obj = comm._new()
    local their_pub_key = crypt.bigint.new(msg)
    obj.their_pub_key = their_pub_key
    if not addresses[address] then
        rednet.send(address,our_pub_key:toString(),prot)
    end
    comm.on_new_comm(obj)
    comm.address = address
    addresses[address] = nil
    return true
end

return comm