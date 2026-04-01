function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

local cryptolib = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")()
local rsa = cryptolib.rsa
local aes = cryptolib.aes
local bignum = cryptolib.bignum

print("generating RSA keypair...")
local pubRSA, privRSA = rsa.generate_keys(64)
print("generating AES-CBC key...")
local my_key = aes.generate_iv()


local init_prot = "init_encrypt"
local msg_prot = "whatever"

local comm = {}
comm.__index = comm

function recieve_from_id(their_id,their_prot)
    their_prot = their_prot or init_prot
    local id,msg,prot = nil,nil,nil
    while true do 
        id,msg,prot = rednet.receive()
        if id == their_id and prot == their_prot then
            return id,msg,prot
        end
    end
end

function comm.initiate(id)
    --0
    print("INITIATING WITH",id)
    rednet.send(id,textutils.serialise({pubRSA[1]:toString(),pubRSA[2]:toString()}),init_prot)
    --1
    local id,their_pub_key,prot = recieve_from_id(id)
    print(id,their_pub_key,prot,"STAGE1")
    local pub_key_deserialised = textutils.unserialise(their_pub_key)
    local their_pub_key = {bignum(pub_key_deserialised[1]),bignum(pub_key_deserialised[2])}
    local encrypted = rsa.encrypt(my_key,privRSA)
    if encrypted then
        --2
        rednet.send(id,encrypted,prot)
        --3
        local id,encrypted_key,prot = recieve_from_id(id)
        print(id,encrypted_key,prot,"STAGE3")
        local their_key = rsa.decrypt(encrypted_key,privRSA)
        if their_key then 
            local self = {}
            self.their_key = their_key
            self.their_id = id
            setmetatable(self,comm)
            return self
        end
    end
end

-- needs signing
function comm.recieve_until_object_created()
    while true do 
        --0 
        local id,serialised_pub_key,prot = rednet.receive()
        print(id,serialised_pub_key,prot,"STAGE0")
        if prot == init_prot then
            local pub_key_deserialised = textutils.unserialise(serialised_pub_key)
            local their_pub_key = {bignum(pub_key_deserialised[1]),bignum(pub_key_deserialised[2])}
            local our_pub_key_serialised = textutils.serialise({pubRSA[1]:toString(),pubRSA[2]:toString()})
            --1
            rednet.send(id,our_pub_key_serialised,prot)
            --2
            local id,encrypted_key,prot = recieve_from_id(id)
            print(id,encrypted_key,prot,"STAGE2")
            local their_key = rsa.decrypt(encrypted_key,privRSA)
            if their_key then
                local encrypted = rsa.encrypt(my_key,privRSA)
                if encrypted then 
                    --3
                    rednet.send(id,encrypted,prot)
                    -- exchanged symmetric keys
                    local self = {}
                    self.their_key = their_key
                    self.their_id = id
                    setmetatable(self,comm)
                    return self
                end
            end
        end
    end
end

function comm:send(plaintext)
   local iv = aes.generate_iv()
   local encrypted = aes.cbc_encrypt(plaintext, self.their_key, iv)
   rednet.send(self.their_id,encrypted,msg_prot)
end

function comm:receive(plaintext)
    while true do
        local id,msg,prot = rednet.receive()
        local decrypted = aes.cbc_decrypt(msg,self.my_key)
        -- authentication comes in the ability to encrypt messages so no digital signing is needed
        if decrypted and prot == msg_prot then
            return decrypted
        end
    end
end

return comm