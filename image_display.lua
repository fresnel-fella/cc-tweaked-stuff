local monitor = peripheral.find("monitor")
function netrequire(file_name)
    return http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name.."").readAll()
end
function get_byte(s,i)
    return string.byte(string.sub(s,i,i))
end
local image = netrequire("output.ccp") -- ccp is not short for chinese communist party it is short for computer craft picture
local width = get_byte(image,1) + get_byte(image,2)*2^8 + get_byte(image,3)*2^16 + get_byte(image,4)*2^24
local height = get_byte(image,1+4) + get_byte(image,2+4)*2^8 + get_byte(image,3+4)*2^16 + get_byte(image,4+4)*2^24
print(width)
print(height)