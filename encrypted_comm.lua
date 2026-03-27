local comm = {}
comm.__index = comm
comm.our_pub_key = nil
comm.our_pri_key = nil
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
local time_a = os.time()
local crypt = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/crypt.lua")()
local time_b = os.time()
local entropy = time_a+time_b+math.floor(os.clock()*1000)
comm.crypt = crypt
local comm_prot = "crypt_comm"
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
local comm_objects = {}

function comm.filter(address,msg,prot)
    if comm_prot == prot then
        if comm_objects[address] then 
            -- unsafe
            local object = comm_objects[address]
            local decrypted = object:decrypt(msg)
            local decrypted_table = textutils.unserialise(decrypted)
            if decrypted_table then
                comm_objects[address].coroutine.resume(decrypted_table)
            end
        end
    end
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

function comm:use_coroutine(func)
    local cor = coroutine.create(func)
    coroutine.resume(co)
    self.coroutine = cor
end

function comm:decrypt(msg)
    local decrypted_msg
    local success = pcall(function() 
        decrypted_msg = crypt.decrypt(msg,comm.our_pri_key)
    end)
    if success and decrypted_msg then
        return decrypted_msg
    end
end
function comm:encrypt(msg)
    local encrypted_msg
    local success = pcall(function() 
        encrypted_msg = crypt.encrypt(msg ,self.their_pub_key)
    end)
    if success and encrypted_msg then
        return encrypted_msg
    end
end

return comm