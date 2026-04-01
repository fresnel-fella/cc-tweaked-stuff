-- ^ should be a "pub_key" variable assigned with the public key of the host here, server can generate this line
if not pub_key then
    printverbose("no pub_key variable here! use the generated file from the server")
    return
end
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
local screendrawing = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/screen_drawing.lua")