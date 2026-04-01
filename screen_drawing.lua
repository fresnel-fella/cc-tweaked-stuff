local module = {}
local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
local sx,sy = monitor.getSize()
printverbose("screen size:",sx,sy)
function module.relative_to_screen_position(x,y)
    return math.floor(x*sx+0.5)+1, math.floor(y*sy+0.5)+1
end
function module.relative_offset_to_screen_position(x,y,ox,oy)
    return math.floor(x*sx+0.5)+1+ox, math.floor(y*sy+0.5)+1+oy
end
function module.clear() monitor.clear() end
local buffer = {}
function module.blit_buffer(x,y,a,b,c,d)
    table.insert(buffer,{x,y,a,b,c,d})
end
function module.render()
    monitor.clear()
    for _,obj in ipairs(buffer) do 
        monitor.setCursorPos(obj[1],obj[2])
        monitor.blit(obj[3],obj[4],obj[5],obj[6])
    end
    buffer = {}
end
function module.draw(x,y,sx,sy,char,text_color,back_color,ox,oy,osx,osy)
    ox = ox or 0
    oy = oy or 0
    osx = osx or 0
    osy = osy or 0
    local x0,y0 = module.relative_to_screen_position(x,y)
    x0 = x0 + ox
    y0 = y0 + oy
    local x1,y1 = module.relative_to_screen_position(x+sx,y+sy)
    x1 = x1 + osx + ox
    y1 = y1 + osy + oy

    local xdiff,ydiff = x1-x0,y1-y0
    printverbose("V this is the character width and height of the thing being drawn")
    printverbose(xdiff,ydiff)
    text_color = colors.toBlit(text_color or colors.white)
    back_color = colors.toBlit(back_color or colors.black)
    for px = 0,xdiff-1,1 do
        for py = 0,ydiff-1,1 do
            module.blit_buffer(x0+px,y0+py,char,text_color,back_color)
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
    for i = 0,string.len(line)-1,1 do
        module.blit_buffer(x0+i,y0,string.sub(line,i+1,i+1),text_color,back_color)
    end
end
printverbose("screen drawing loaded")
return module