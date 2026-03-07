local module = {}
local recursive_protocol = "rec"
local root_protocol = "root_dns"
local protocol = "dns"
local cert_protocol = "cert"

local root_public_key = ""

function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
local cryptolib = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")()

function module.split_name(str)
    local primary = nil
    local secondary = nil
    local tertiary = nil
    local buffer = ""
    for i = 1, #str do
        -- get substring of 1 chracter
        local c = str:sub(i,i)
        if c == "." then
            if primary == nil then
                primary = buffer
            elseif secondary == nil then 
                secondary = buffer
            elseif tertiary == nil then
                tertiary = buffer
            else
                return nil
            end
        else
            buffer = buffer .. c
        end
    end
    if (primary:len() > 0 and secondary:len() > 0 and tertiary:len() > 0) then
        return {tertiary,secondary,primary}
    elseif (primary:len() > 0 and secondary:len() > 0) then
        return {secondary,primary}
    end
    return nil
end

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

function module.random_hexs(bytes_of_entropy)
    local str = ""
    for i = 1,bytes_of_entropy do 
        str = str .. module.random_hex()
    end
    return str
end

function module.verify_server(id,public_key)
    local to_sign = module.random_hexs(8)
    local verify_message = "S" .. to_sign
    rednet.send(id,verify_message,cert_protocol)
    local signed = module.recieve(id,cert_protocol)
    if signed == nil then return false end
    local t = cryptolib.ecc.verify(public_key,to_sign,signed)
    if t.result then
        return true
    end
    return false
end

function module.send_verified(id,msg,private_key)
    if not msg:sub(1,1) == "S" then return end
    for i = 2,msg:len(),1 do 
        local char = msg:sub(i,i)
        local is_hex = false
        for char_b in hex do 
            if char == char_b then 
                is_hex = true
            end
        end
        if is_hex == false then return end
    end
    -- its good format
    local signed = cryptolib.ecc.sign(private_key,msg:sub(1,-1))
    rednet.send(id,signed,cert_protocol)
end

function module.find_dns(hostname)
    if not module.split_name(hostname) then return nil end
    local recursive_servers = rednet.lookup(protocol)
    for _, server_id in pairs(computers) do
        rednet.send(server_id,"R"..hostname,protocol)
        local server = module.recieve(server_id,protocol)
        if server then

        end
    end
end

function module.send_signed(message,id,private_key)
    local signature = cryptolib.ecc.sign(private_key,message)
    local msg_start = signature:len()+2
    return string.char(msg_start) .. signature .. message
end

function module.recieve_signed(id,prot,public_key)
    local msg = module.recieve(id,prot)
    if msg then 
        local true_msg_start = msg:sub(1,1):byte(1,1)
        local true_msg = msg:sub(true_msg_start,-1)
        local sig = msg:sub(1,true_msg_start-1)
        if cryptolib.ecc.verify(public_key,true_msg,sig).result then 
            return true_msg
        end
    end

end

return module