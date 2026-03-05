function netrequire(file_name)
    local out,error = load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name).readAll())
    if error then error(error) end
    return out
end
print("starting banking...")
netrequire("banking/encryption.lua")(_G)