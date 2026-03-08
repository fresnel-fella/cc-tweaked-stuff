local module = {}
module.verbose = false

local handle = {}
handle.__index = handle

local crypt = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/crypt.lua")
local ver_prot = "verify"
local asymetric_prot = "asy"
local bank_prot = "bank_req"

function recieve(id,prot)
    local msg = nil
    local old = os.clock()
    repeat
        local this_id, this_msg = rednet.recieve(prot,1)
        if this_id == id then
            msg = this_msg
        end
    until msg ~= nil or os.clock() - old > 1
    return msg
end
function printverbose(...)
    if module.verbose then 
        print(...)
    end
end

function module.new_connection(bank_pub_key,your_pub_key,your_priv_key)
    printverbose("creating new connection with the server")
    peripheral.find("modem", rednet.open)
    if not bank_pub_key then return end
    if not your_pub_key then return end
    local self = {}
    setmetatable(self,handle)
    self.sig_pub_key = bank_pub_key
    self.your_asy_pub_key = your_pub_key
    self.your_asy_pri_key = your_priv_key
    self.logged_in = false
    local computers = rednet.lookup("bank")
    local verified = nil
    for _, computer in computers do
        local msg = string.random_hexs(8)
        rednet.send(computer,msg,ver_prot)
        local signature = recieve(computer,ver_prot)
        if signature and crypt.verify(bank_pub_key,msg,signature) then
            verified = computer
            break
        end
    end
    if not verified then return end
    printverbose("server is authentic")

    rednet.send(verified,"K",bank_prot)
    self.asy_pub_key = recieve(verified,bank_prot)
    if not self.asy_pub_key then return end

    self.server = verified
    return self
end

function handle:_recieve_encrypted()
    local rec_msg = recieve(self.server,bank_prot)
    if not rec_msg then return end
    local true_msg = crypt.decrypt(rec_msg,self.your_asy_pri_key)
    if not true_msg then return end
    return textutils.unserialize(true_msg)
end
function handle:_send_encrypted(msg)
    local encrypted = crypt.encrypt(textutils.serialize(msg),self.asy_pub_key)
    rednet.send(self.server,encrypted,bank_prot)
end

function handle:_get_encrypted(msg)
    self:_send_encrypted(msg)
    return self:_recieve_encrypted()
end

function handle:get_balance()
    handle:_send_encrypted({
        ["type"] = "get_bal",
    })
end
function handle:send_money(user,amount) end

function handle:sign_in(user,pass)
    local rec_msg = handle:_get_encrypted({
        ["type"] = "login",
        ["user"] = user,
        ["pass"] = pass
    })
    if not rec_msg then return end
    if rec_msg.type == "login" and rec_msg.success then
        self.logged_in = true
        return true
    else
        return false
    end
end

return module