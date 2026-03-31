local module = {}
local cert_protocol = "cert"

function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
local cryptolib = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")()

function module.recieve(desired_id,prot)
    local from_id, message = rednet.recieve(prot,5)
    if message == nil then return nil end
    if from_id ~= desired_id then return module.recieve(desired_id,prot) end
    return message
end
local hex = {"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"}
function module.random_hex()
    local index = math.random(1,16)
    return hex[index]
end -- not actually truly random but who gaf

function module.random_hexs(bytes_of_entropy,seed)
    if seed then math.randomseed(os.time() + math.floor(os.clock()*10000)) end
    local str = ""
    for i = 1,bytes_of_entropy do 
        str = str .. module.random_hex()
    end
    return str
end

function module.send_signed(message,private_key)
    local signature = cryptolib.ecc.sign(private_key,message)
    local msg_start = signature:len()+2
    local signed_msg = string.char(msg_start) .. signature .. message
    return signed_msg
end

function module.sign(msg,priv_key)
    return cryptolib.ecc.sign(priv_key,msg)
end

function module.verify(sig,msg,pub_key)
    return cryptolib.ecc.verify(pub_key,msg,sig).result
end

function module.recieve_signed(msg,public_key)
    if msg then 
        local true_msg_start = msg:sub(1,1):byte(1,1)
        local true_msg = msg:sub(true_msg_start,-1)
        local sig = msg:sub(1,true_msg_start-1)
        if cryptolib.ecc.verify(public_key,true_msg,sig).result then
            return true_msg
        end
    end
end

function module.generate_keys()
    local privA = cryptolib.ecc.generatePrivateKey()
    local pubA = cryptolib.ecc.getPublicKey(privA)
    return privA,pubA
end

function module.generate_asy_keys()
    local pubA,privA = cryptolib.rsa.generate_keys(64)
    return privA,pubA
end

-- DONT USE RSA DIRECTLY YOU GOOBER

module.bignum = cryptolib.bignum
module.encrypt = cryptolib.rsa.encrypt
module.decrypt = cryptolib.rsa.decrypt

return module