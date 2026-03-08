local random_monitor = peripheral.find("monitor")
--print(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll())
--load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll())()
--local fun, error = load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll()) print(error) fun()
function get_byte(s,i)
    return s:sub(i,i):byte(1,1)
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
local image = read_file("boot_img.ccp")
local config = read_file("image.cfg")
if not config then
    config = {}
    print("config not detected")
    print("type network names of monitors in right wrapping to downwards order starting at the top left")
    print("monitors must be uniform size")
    local input = ""
    while input ~= "STOP" do 
        print("monitors> ")
        input = read()
        if input ~= "STOP" then 
            table.insert(config,input)
        end
    end
    local serialized = textutils.serialize(config)
    local handle = io.open("image.cfg","w")
    handle:write(serialized)
    handle:close()
else
    config = textutils.unserialize(config)
end
for _, monitor_name in pairs(config) do
    local monitor = peripheral.wrap(monitor_name)
    monitor.clear()
    monitor.setTextScale(0.5)
end
local mon_width,mon_height = random_monitor.getSize()
local width = get_byte(image,1) + get_byte(image,2)*2^8 + get_byte(image,3)*2^16 + get_byte(image,4)*2^24
local height = get_byte(image,1+4) + get_byte(image,2+4)*2^8 + get_byte(image,3+4)*2^16 + get_byte(image,4+4)*2^24
print(width)
print(height)
local i = 9
local yieldi = 0
for y = 1,height do
    for x = 1,width do
        local mon_x = (x-1)%mon_width + 1
        local mon_y = (y-1)%mon_height + 1
        local mon_i = 1 + math.floor((y-1)/mon_height) + math.floor((x-1)/mon_width)*(height/mon_height)
        print(mon_i)
        mon_i = math.min(mon_i,#config)
        local monitor = peripheral.wrap(config[mon_i])
        local byte = get_byte(image,i)
        local primary = (byte) % 16
        local secondary = ((byte-primary) / (2^4))
        primary = 2^(primary)
        secondary = 2^(secondary)
        print(primary)
        print(secondary)
        print(config[mon_i])
        print(mon_x)
        print(mon_y)
        local primary_color = primary
        local secondary_color = secondary
        monitor.setCursorPos(mon_x,mon_y)
        monitor.blit(string.char(127),colors.toBlit(primary_color),colors.toBlit(secondary_color))
        i = i + 1
        yieldi = yieldi + 1
    end
    if yieldi > 10000 then
        os.sleep(1)
        yieldi = 0
    end
end