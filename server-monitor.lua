function netrequire(file_name)
    return load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name..".lua").readAll())()
end
print("starting monitor")
local screen_drawing = netrequire("screen_drawing")
local x_increment,y_increment = screen_drawing.get_xy_increment()
while true do
    screen_drawing.draw(0,0,1,1,"h",colors.cyan,colors.blue)
    screen_drawing.draw(0.05,0.05,0.9,0.9," ",nil,colors.white)
    screen_drawing.draw(0.05,0.95,0.9,x_increment," ",nil,colors.grey)
    screen_drawing.draw(0.95,0.05,y_increment,0.9," ",nil,colors.grey)
    screen_drawing.draw_text_centred("hello world!",0.5,0.5,colors.black,colors.white)
    screen_drawing.render()
    sleep(1)
end