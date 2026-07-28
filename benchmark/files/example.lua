urls = {
    "/",
    "/index.html"
}

counter = 0

request = function()
    counter = counter + 1
    path = urls[(counter % #urls) + 1]
    return wrk.format("GET", path)
end