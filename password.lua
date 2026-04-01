function netrequire(file_name)
    return load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name..".lua").readAll())()
end
print("starting monitor")
local screen_drawing = netrequire("screen_drawing")
--local password = require("actual_password")
function draw_box(x,y,sx,sy)
    screen_drawing.draw(x,y,sx,sy," ",nil,colors.lightGray)
    screen_drawing.draw(x,y,0,sy," ",nil,colors.white,0,0,1,0)
    screen_drawing.draw(x,y,sx,0," ",nil,colors.white,0,0,0,1)
    screen_drawing.draw(x+sx,y,0,sy," ",nil,colors.gray,-1,0,1,0)
    screen_drawing.draw(x,y+sy,sx,0," ",nil,colors.gray,0,-1,0,1)
    screen_drawing.draw(x+sx,y,0,0,"X",colors.black,colors.red,-1,0,1,1)
    screen_drawing.draw(x+sx,y,0,0,"#",colors.black,colors.orange,-2,0,1,1)
    screen_drawing.draw(x+sx,y,0,0,"-",colors.black,colors.green,-3,0,1,1)
end
local button_length = 5
local button_positions = {{0,0,"0"},{1,0,"1"},{2,0,"2"},{0,1,"4"},{1,1,"5"},{2,1,"6"},{0,2,"7"},{1,2,"8"},{2,2,"9"}}
local pin = ""

function draw_buttons(x,y)
    for _,button in pairs(button_positions) do 
        local bx,by = button[1],button[2]
        screen_drawing.draw(0,0,0,0,button[3],colors.white,colors.green,bx,by,1,1)
        if x == bx and y == by then
            pin = pin .. button[3]
        end
    end
end
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    screen_drawing.draw(0,0,1,1,"h",colors.cyan,colors.blue)
    draw_box(0.05,0.05,0.9,0.9)
    draw_buttons(x,y)
    if string.len(pin) >= 5 then
        pin = ""
    end
    screen_drawing.draw_text_centred(pin,0.5,0,colors.black,colors.lightGray)
    screen_drawing.render()
end
