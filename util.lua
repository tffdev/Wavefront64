-- UTILITIES
function err()
	print("ERROR: no file input")
	os.exit(1)
end

function intToBin(x)
	ret=""
	while x~=1 and x~=0 do
		ret=tostring(x%2)..ret
		x=math.modf(x/2)
	end
	ret=tostring(x)..ret
	return ret
end

function readFile(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

function padBinaryLeft(s,l)
	local outstring = s
	for _= #s + 1,l do
		outstring = "0"..outstring
	end
	return outstring
end

function padStringLeft(s,l)
	local outstring = "                          "
	outstring = string.sub(outstring,0,l-#tostring(s))..s
	return outstring
end