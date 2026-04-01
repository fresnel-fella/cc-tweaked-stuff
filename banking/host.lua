function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
function read_file(path)
    local h
    local success = pcall(function()
        h = io.open(path,"r")
    end)
    if success and h then
        local stuff = h:read("a")
        h:close()
        return stuff
    end
end
function write_file(path,contents)
    local h
    local success = pcall(function()
        h = io.open(path,"w")
    end)
    if success and h then
        h:write(contents)
        h:close()
    end
end
local crypt = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/crypt.lua")
printverbose("starting banking server...")
local keys = read_file("./signature.key")
if keys then
    keys = textutils.unserialize(keys)
    printverbose("found keys file")
else
    printverbose("no keys file detected, would you like to generate them? [y/N]")
    printverbose("make sure the server is at a secure location, someone with these keys could imitate your server!")
    if read():lower() == "y" then
        printverbose("generating keys...")
        local priv,pub = crypt.generate_keys()
        printverbose("done!")
        keys = {
            ["priv"] = priv:toString(),
            ["pub"] = pub:toString()
        }
        write_file("./signature.key",textutils.serialize(keys))
        printverbose("generating client program...")
        local rest = http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/banking/client.lua").readAll()
        local start_line = "local pub_key = " .. "\"" .. pub:toString() .. "\"" .. "\n"
        local contents = start_line..rest
        write_file("./client.lua",contents)
        printverbose("done!")
    else
        return
    end
end
printverbose("setup done!")

