local monitor = peripheral.find("monitor")
--print(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll())
--load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll())()
--local fun, error = load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/image_display.lua").readAll()) print(error) fun()
function get_byte(s,i)
    return string.byte(string.sub(s,i,i))
end
function read_file(path)
    local h = io.open(path,"r")
    local stuff = h:read("a")
    h:close()
    return stuff
end
monitor.setTextScale(0.5)
local image = read_file("boot_img.ccp")
local width = get_byte(image,1) + get_byte(image,2)*2^8 + get_byte(image,3)*2^16 + get_byte(image,4)*2^24
local height = get_byte(image,1+4) + get_byte(image,2+4)*2^8 + get_byte(image,3+4)*2^16 + get_byte(image,4+4)*2^24
print(width)
print(height)
local i = 9
monitor.clear()
for y = 1,height do
    for x = 1,width do
        local byte = get_byte(image,i)
        local primary = (byte) % 16
        local secondary = ((byte-primary) / (2^4))
        primary = 2^(primary)
        secondary = 2^(secondary)
        print(primary)
        print(secondary)
        local primary_color = primary
        local secondary_color = secondary
        monitor.setCursorPos(x,y)
        monitor.blit(string.char(127),colors.toBlit(primary_color),colors.toBlit(secondary_color))
        i = i + 1
    end
end