function netrequire(file_name)
    return load(http.get("https://raw.githubusercontent.com/fresnel-fella/cc-tweaked-stuff/refs/heads/main/"..file_name..".lua").readAll())()
end
local screen_drawing = netrequire("screen_drawing")
screen_drawing.clear()
screen_drawing.draw(0.25,0.25,0.5,0.5,"h")
