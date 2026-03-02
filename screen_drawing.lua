local module = {}
local monitor = peripheral.find("monitor")
function module.relative_to_screen_position(x,y)
    local sx,sy = monitor.getSize()
    return math.floor((x-1)/(sx-1)+0.5), math.floor((y-1)/(sy-1)+0.5)
end
function module.clear() monitor.clear() end
function module.draw(x,y,sx,sy,char,text_color,back_color)
    local x0,y0 = module.relative_to_screen_position(x,y)
    local x1,y1 = module.relative_to_screen_position(x+sx,y+sy)
    local xdiff,ydiff = x1-x0,y1-y0
    text_color = text_color or colors.white
    back_color = back_color or colors.black
    for px = 0,xdiff-1,1 do
        for py = 0,ydiff-1,1 do
            print(px,py)
            monitor.setCursorPos(x0+px,y0+py)
            monitor.blit(char,text_color,back_color)
        end
    end
end
return module