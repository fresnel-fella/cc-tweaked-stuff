print("bankin time")
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
print("loading comm...")
local comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm2.lua")()
print("done!")
print("loading idarcrypto...")
local crypto = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")()
print("done!")
print("loading listener...")
local listener_holder = {}
netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/listen.lua")()(listener_holder,function()
    local listener = listener_holder[1]
    comm.listener = listener
    local ecc = crypto.ecc


    function read_file(path)
        local h
        local success = pcall(function()
            h = io.open(path, "r")
        end)
        if success and h then
            local stuff = h:read("a")
            h:close()
            return stuff
        end
    end

    function setup()
        print("welcome to the setup stage!")
        print("if this is an error, stop the program now.")
        print("otherwise, press enter")
        io.read()
        print("generating authentication certificate...")
        local privA = ecc.generatePrivateKey()
        local pubA = ecc.getPublicKey(privA)
        local handle = io.open("keys.data","w")
        handle:write(textutils.serialise({["pub"]=pubA,["priv"]=privA}))
        handle:close()
        print("certificate saved in keys.data")
        print("generating empty database...")
        local handle = io.open("banking.data","w")
        handle:write(textutils.serialise({["users"] = {}}))
        handle:close()
        print("all done!")
    end

    print("loading database...")
    local data_base = read_file("banking.data")
    if not data_base then
        print("no database detected...")
        setup()
        data_base = read_file("banking.data")
    end
    data_base = textutils.unserialise(data_base)
    local keys = textutils.unserialise(read_file("keys.data"))
    local pub = keys.pub
    local priv = keys.priv

    -- loaded
    function split(str) 
        local list = {}
        local buffer = ""
        for i = 1,str:len() do 
            local char = str:sub(i,i)
            if char ~= " " then 
                buffer = buffer .. char
            else
                table.insert(list,buffer)
                buffer = ""
            end
        end
        return list
    end

    function save()
        print("saving...")
        local handle = io.open("banking.data","w")
        handle:write(textutils.serialise(data_base))
        handle:close()
        print("done saving!")
    end

    local commands = {}
    function console()
        print("console has been setup, type [help] for more commands")
        while true do
            command = io.read()
            table.insert(commands,split(command))
        end
    end
    local comm_obj = nil
    function receiver()
        print("receiving...")
        local object = comm.receive_until_object_created()
        comm_obj = object
        parallel.waitForAll(receiver,on_new_comm)
    end
    local counter = 0
    function on_new_comm()
        counter = counter + 1
        local our_counter = counter - 1
        local comm = comm_obj
        while true do 
            local msg = textutils.unserialise(comm:receive())
            if msg.type == "login" and msg.password and msg.user and type(msg.password)=="string" and type(msg.user)=="string" then
                local user = data_base.users[msg.user]
                local username = msg.user
                if user and user.password == msg.password then
                    comm:send(textutils.serialise({
                        ["type"] = "status",
                        ["success"] = true,
                    }))
                    -- logged in
                    while true do
                        local msg = textutils.unserialise(comm:receive())
                        if msg.type == "balance" then
                            comm:send(textutils.serialise({
                                ["type"] = "balance",
                                ["balance"] = user.balance,
                            }))
                        elseif msg.type == "send" and msg.amount and msg.receiving and type(msg.amount)=="number" and type(msg.receiving)=="string" and data_base["users"][msg.receiving] and data_base["users"][msg.receiving]~=user then
                            if msg.amount <= user.balance then 
                                transactions[our_counter] = {["amount"]=msg.amount,["user"]=username,["receiving"]=data_base["users"][msg.receiving]}
                            end
                        end
                    end
                else
                    comm:send(textutils.serialise({
                        ["type"] = "status",
                        ["success"] = false,
                    }))
                end
            else
                comm:send(textutils.serialise({
                    ["type"] = "status",
                    ["success"] = false,
                }))
            end
        end
    end
    local transactions = {}
    function transaction_thread()
        while true do
            local now_transactions = transactions
            transactions = {}
            local transaction_done = false
            for _, transaction in pairs(now_transactions) do
                local sender = data_base["users"][transaction.user]
                local recipient = data_base["users"][transaction.receiving]
                local amount = transaction.amount
                if amount <= sender.balance then
                    sender.balance = sender.balance - amount
                    recipient.balance = recipient.balance + amount
                    transaction_done = true
                end
            end
            local now_commands = commands
            commands = {}
            for _, command in pairs(now_commands) do
                if command[1] == "newuser" then
                    if command[2] and command[3] and command[2]:len()>1 and command[3]:len()>1 then
                        local amount = 0
                        if command[4] then
                            amount = tonumber(amount)
                        end
                        transaction_done = true
                        data_base["users"][command[2]] = {
                            ["username"] = command[2],
                            ["password"] = command[3],
                            ["balance"] = amount
                        }
                        print("successfully made user")
                    end
                elseif command[1] == "rmuser" then
                    if command[2] and command[2]:len()>1 and data_base["users"][command[2]] then
                        data_base["users"][command[2]] = nil
                        print("successfully removed user")
                    end
                elseif command[1] == "ls" then
                    for k,obj in pairs(data_base["users"]) do
                        print(k,obj.balance)
                    end
                elseif command[1] == "addbalance" and command[2] and command[3] and tonumber(command[3]) and data_base["users"][command[2]] then
                    data_base["users"][command[2]].balance = data_base["users"][command[2]].balance + tonumber(command[3])
                end
            end
            if transaction_done then
                save()
            end
            os.sleep(0.1)
        end
    end
    parallel.waitForAll(console,receiver,transaction_thread)

end)