print("bankin time")
function netrequire(file_name)
    local out,error = load(http.get(file_name).readAll())
    if error then error(error) end
    return out
end
print("loading comm...")
local comm = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/encrypted_comm2.lua")
print("done!")
print("loading idarcrypto...")
local crypto = netrequire("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/idarcryptocompressed.lua")
print("done!")
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

function save()
    print("saving...")
    local handle = io.open("banking.data","w")
    handle:write(textutils.serialise(data_base))
    handle:close()
    print("done saving!")
end


function console()
    print("console has been setup, type [help] for more commands")
end
function receiver()
    print("receiving...")
    local object = comm.receive_until_object_created()
end
function on_new_comm(comm)
    
end