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
local signing = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/signing.lua")
print("starting banking server...")
local keys = read_file("./signature.key")
if keys then
    keys = textutils.unserialize(keys)
    print("found keys file")
else
    print("no keys file detected, would you like to generate them? [y/N]")
    print("make sure the server is at a secure location, someone with these keys could imitate your server!")
    if read():lower() == "y" then
        print("generating keys...")
        local priv,pub = signing.generate_keys()
        print("done!")
        keys = {
            ["priv"] = priv:toString(),
            ["pub"] = pub:toString()
        }
        write_file("./signature.key",textutils.serialize(keys))
        print("generating client program...")
        local rest = http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/banking/client.lua").readAll()
        local start_line = "local pub_key = " .. "\"" .. pub:toString() .. "\"" .. "\n"
        local contents = start_line..rest
        write_file("./client.lua",contents)
        print("done!")
    else
        return
    end
end
print("setup done!")

