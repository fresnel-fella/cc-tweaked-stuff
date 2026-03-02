local module = {}
local monitor = peripheral.find("monitor")
local sx,sy = monitor.getSize()
print("screen size:",sx,sy)
function module.relative_to_screen_position(x,y)
    return math.floor(x*sx+0.5), math.floor(y*sy+0.5)
end
function module.clear() monitor.clear() end
function module.draw(x,y,sx,sy,char,text_color,back_color)
    local x0,y0 = module.relative_to_screen_position(x,y)
    local x1,y1 = module.relative_to_screen_position(x+sx,y+sy)
    local xdiff,ydiff = x1-x0,y1-y0
    print("V this is the character width and height of the thing being drawn")
    print(xdiff,ydiff)
    text_color = colors.toBlit(text_color or colors.white)
    back_color = colors.toBlit(back_color or colors.black)
    for px = 0,xdiff-1,1 do
        for py = 0,ydiff-1,1 do
            print(px,py)
            monitor.setCursorPos(x0+px,y0+py)
            print(char)
            monitor.blit(char,text_color,back_color)
        end
    end
end
function module.get_xy_increment()
    return 1/sx,1/sy
end
function module.draw_text_centred(line,x,y,text_color,back_color)
    text_color = colors.toBlit(text_color or colors.white)
    back_color = colors.toBlit(back_color or colors.black)
    local x0,y0 = module.relative_to_screen_position(x,y)
    x0 = x0 - math.floor(string.len(line)/2+0.5)
    monitor.setCursorPos(x0,y0)
    for i = 0,string.len(line)-1,1 do
        monitor.setCursorPos(x0+i,y0)
        monitor.blit(string.sub(line,i+1,i+1),text_color,back_color)
    end
end
print("screen drawing loaded")
return module