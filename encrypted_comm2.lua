function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end

local cryptolib = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")()
local rsa = cryptolib.rsa
local chacha = cryptolib.chacha
local bignum = cryptolib.bignum

print("generating RSA keypair...")
local pubRSA, privRSA = rsa.generate_keys(64)
print(pubRSA[1],"pubRSA")


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
    print("generating key...")
    local my_key = string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))
    print(my_key,"my_key")
    print("START")
    --0
    print("INITIATING WITH",id)
    rednet.send(id,textutils.serialise({pubRSA[1]:toString(),pubRSA[2]:toString()}),init_prot)
    --1
    local id,something,prot = recieve_from_id(id)
    local their_pub_key = something[1]
    local nonce = something[2]
    print("nonce:",nonce)
    print(id,their_pub_key,prot,"STAGE1")
    local pub_key_deserialised = textutils.unserialise(their_pub_key)
    local their_pub_key = {bignum(pub_key_deserialised[1]),bignum(pub_key_deserialised[2])}
    print(their_pub_key[1],"their_pub_key[1]")
    local encrypted = rsa.encrypt(my_key,privRSA)
    if encrypted then
        --2
        print("for whatever reason i think encrypted is a table")
        for k,v in pairs(encrypted) do 
            print(k,",",v)
        end
        rednet.send(id,encrypted:toString(),prot)
        --3
        local id,encrypted_key,prot = recieve_from_id(id)
        print(id,encrypted_key,prot,"STAGE3")
        local their_key = rsa.decrypt(bignum(encrypted_key),privRSA)
        if their_key then 
            print(their_key)
            local self = {}
            self.their_key = their_key
            self.their_id = id
            self.nonce = nonce
            setmetatable(self,comm)
            return self
        end
    end
end

-- needs signing
function comm.receive_until_object_created()
    print("generating key...")
    local my_key = string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))..string.char(math.random(0,255))
    print(my_key,"my_key")
    print("START")
    while true do
        print("generating nonce...")
        local nonce = chacha.generateNonce() -- please kill me for sending this in plaintext over the network i dont know how this works
        print(nonce,"nonce")
        --0 
        local id,serialised_pub_key,prot = rednet.receive()
        print(id,serialised_pub_key,prot,"STAGE0")
        if prot == init_prot then
            local pub_key_deserialised = textutils.unserialise(serialised_pub_key)
            local their_pub_key = {bignum(pub_key_deserialised[1]),bignum(pub_key_deserialised[2])}
            print(their_pub_key[1],"their_pub_key[1]")
            local our_pub_key_serialised = textutils.serialise({pubRSA[1]:toString(),pubRSA[2]:toString()})
            --1
            rednet.send(id,{our_pub_key_serialised,nonce},prot)
            --2
            local id,encrypted_key,prot = recieve_from_id(id)
            print(id,encrypted_key,prot,"STAGE2")
            local their_key = rsa.decrypt(bignum(encrypted_key),privRSA)
            print("blele")
            if their_key then
                local encrypted = rsa.encrypt(my_key,pubRSA)
                if encrypted then 
                    --3
                    rednet.send(id,encrypted:toString(),prot)
                    -- exchanged symmetric keys
                    print(their_key,"their_key")
                    local self = {}
                    self.their_key = their_key
                    self.their_id = id
                    self.my_key = my_key
                    self.nonce = nonce
                    setmetatable(self,comm)
                    return self
                end
            end
        end
    end
end

function comm:send(plaintext)
   local encrypted = chacha.encrypt(plaintext, self.their_key, self.nonce)
   rednet.send(self.their_id,encrypted,msg_prot)
end

function comm:receive(plaintext)
    while true do
        local id,msg,prot = rednet.receive()
        print("received presumably encrypted message from",id,"containing",msg)
        local decrypted = chacha.decrypt(msg,self.my_key,self.nonce)
        print("decrypted message: ",decrypted)
        -- authentication comes in the ability to encrypt messages so no digital signing is needed
        if decrypted and prot == msg_prot then
            return decrypted
        end
    end
end

return comm