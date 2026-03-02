function netrequire(file_name)
    return load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name..".lua").readAll())()
end
print("starting monitor")
local screen_drawing = netrequire("screen_drawing")
local x_increment,y_increment = screen_drawing.get_xy_increment()
function draw_box(x,y,sx,sy)
    screen_drawing.draw(x,y,sx,sy," ",nil,colors.lightGray)
    screen_drawing.draw(x,y,0,sy," ",nil,colors.white,0,0,1,0)
    screen_drawing.draw(x,y,sx,0," ",nil,colors.white,0,0,0,1)
    screen_drawing.draw(x+sx,y,0,sy," ",nil,colors.black,-1,0,1,0)
    screen_drawing.draw(x,y+sy,sx,0," ",nil,colors.black,0,-1,0,1)
end
while true do
    screen_drawing.draw(0,0,1,1,"h",colors.cyan,colors.blue)
    draw_box(0.05,0.05,0.9,0.9)
    screen_drawing.draw_text_centred("hello world!",0.5,0.5,colors.black,colors.lightGray)
    screen_drawing.render()
    sleep(1)
end