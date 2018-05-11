bitmap = require("bitmap")
obj_loader = require("obj_loader")
require("BinDecHex")
require("util")

--[[ 
==========================
 START OF PROCEDURAL CODE
==========================
--]] 

final_file_output = {}
object_scale = 30
two_tris = true

-- INPUT error checking
if(arg[1]==nil) then
	err("ERROR: No file input")
end

objectName = string.match(arg[1], "([A-Za-z0-9]+)")

mtl_file = readFile(objectName..".mtl")
if(mtl_file == nil) then err("ERROR: No MTL file found.") else print("MTL file "..objectName..".mtl found.") end

-- init object
object = obj_loader.load(objectName..".obj")
if(object==nil) then
	err(objectName..".obj not found")
else
	print("OBJ File "..objectName..".obj found.")
end

-- init bitmap
image_file_name, name_of_texture = string.match(mtl_file, "map_Kd (([A-Za-z]+).[A-Za-z]+)")
bmp = bitmap.from_file(image_file_name)
if(bmp==nil) then
	err("ERROR: File "..image_file_name.." doesn't exist, or file isn't a bitmap")
else
	print("BMP File "..image_file_name.." found.")
end



--[[ 
=======================================
 BITMAP PARSING TO BIG HEX-Y CHUNKS
=======================================
--]] 
print("Parsing bitmap...")
table_of_bytes = {}
table_preview = {}
preview_tokens = {" ",".",":","-","=","+","*","#","%","@"}
for i=0,bmp.width-1 do
	for j=bmp.height-1,0,-1 do
		r,g,b = bmp:get_pixel(i,j)
		if(j==bmp.height-1) then
			table.insert(table_preview,"\n\t")
		end
		table.insert(table_preview,preview_tokens[math.floor((((r+g+b)/(255*3))*#preview_tokens)+0.5)])

		local binstring = intToBin(math.floor(r/8))..intToBin(math.floor(g/8))..intToBin(math.floor(b/8)).."1"
		binstring = padBinaryLeft(binstring)
		local outstring = "0x"..string.lower(Bin2Hex(binstring))..","
		if(j==0) then outstring = "\t"..outstring end
		if(j==bmp.height-1) then outstring = outstring.."\n" end
		table.insert(table_of_bytes,outstring)
	end
end
print("Success parsing bitmap!")
table.insert(final_file_output,"/*\nObject Name: "..objectName.."\nObject Scaling Factor: "..object_scale.."\n\nTexture preview:"..table.concat(table_preview).."\n*/")
table.insert(final_file_output,"unsigned short Text_"..objectName.."_"..name_of_texture.."_diff[] = {\n"..table.concat(table_of_bytes).."};")


--[[ 
=======================================
 FACES AND VERTS OUTPUT (gsSP2Triangles)
=======================================
--]]
print("Creating faces and verts...")

faceTable = {}
vertexTable = {}
vertexOutputTable = {}
vertsCreated = 0
-- generate faces array
for i=1,#object.f do
	local faceVertReference = {}
	faceVertReference[1] = (object.f[i][1].v-2 >= 0 and object.f[i][1].v-2 or #object.f-1)
	faceVertReference[2] = (object.f[i][2].v-2 >= 0 and object.f[i][2].v-2 or #object.f-1)
	faceVertReference[3] = (object.f[i][3].v-2 >= 0 and object.f[i][3].v-2 or #object.f-1)

	for j=1,3 do
		if(vertexTable[tostring(object.f[i][j].v.."/"..object.f[i][j].vt)] == nil)then
			--[[ 
				make vert STRING for THIS unique combination
				TODO: change 130 to the actual vert colors (if any)
			--]] 
			local vertString = "\t{"..
				padStringLeft(math.floor(object_scale*object.v[object.f[i][j].v].x),8)..","..
				padStringLeft(math.floor(object_scale*object.v[object.f[i][j].v].y),8)..","..
				padStringLeft(math.floor(object_scale*object.v[object.f[i][j].v].z),8)..","..
				padStringLeft("0",8)..","..
				padStringLeft((2*object_scale*(bmp.height+1)*object.vt[object.f[i][j].vt].v),8)..","..
				padStringLeft((2*object_scale*(bmp.width+1)*object.vt[object.f[i][j].vt].u),8)..",     130,     130,     130,     0}, //vert "..object.f[i][j].v.."/"..object.f[i][j].vt..", reference: "..vertsCreated

			-- make vertex
			vertexTable[tostring(object.f[i][j].v.."/"..object.f[i][j].vt)] = {
				index = vertsCreated,
				content = vertString
			}
			faceVertReference[j] = vertexTable[object.f[i][j].v.."/"..object.f[i][j].vt].index
			vertsCreated = vertsCreated + 1
			table.insert(vertexOutputTable,vertexTable[object.f[i][j].v.."/"..object.f[i][j].vt].content)
		else
			faceVertReference[j] = vertexTable[object.f[i][j].v.."/"..object.f[i][j].vt].index
		end
	end
	faceTable[i] = {faceVertReference[1],faceVertReference[2],faceVertReference[3]}
end

-- create face output strings
faceOutputTable = {}
table.insert(faceOutputTable,"\tgsSPVertex(&Vtx_"..objectName.."_mesh01_0[0], "..vertsCreated..", 0)")
for i=1,#faceTable, 2 do
	if(#faceTable-i > 0) then
		table.insert(faceOutputTable,"gsSP2Triangles("..faceTable[i][1]..", "..faceTable[i][2]..", "..faceTable[i][3]..", 0, "..faceTable[i+1][1]..", "..faceTable[i+1][2]..", "..faceTable[i+1][3]..", 0)")
	else
		table.insert(faceOutputTable,"gsSP1Triangle("..faceTable[i][1]..", "..faceTable[i][2]..", "..faceTable[i][3]..", 0)")
	end
end

-- output verts
table.insert(final_file_output,"Vtx_tn Vtx_"..objectName.."_mesh01_0["..#vertexOutputTable.."] = {\n"..table.concat(vertexOutputTable,"\n").."\n};")
-- output faces
table.insert(final_file_output,"Gfx Vtx_"..objectName.."_mesh01_dl[] = {\n"..table.concat(faceOutputTable,",\n\t")..",\n\tgsSPEndDisplayList(),\n};")

print("Success creating faces and verts!")




-- output final display list
table.insert(
	final_file_output,
	"Gfx Wtx_"..objectName.."[] = {\n\tgsDPLoadTextureBlock(Text_"..objectName.."_"..name_of_texture..
	"_diff, G_IM_FMT_RGBA, G_IM_SIZ_16b,\n\t\t32,32, 0, G_TX_WRAP|G_TX_NOMIRROR, G_TX_WRAP|G_TX_NOMIRROR,\n\t\t5,5, G_TX_NOLOD, G_TX_NOLOD),\n\tgsSPDisplayList(Vtx_"
	..objectName.."_mesh01_dl),\n\tgsSPEndDisplayList()\n};"
)

file = io.open(objectName..".h","w")
io.output(file)
io.write(table.concat(final_file_output,"\n\n"))
io.close(file)

print("=================================\nDONE!\nOutput file: \n"..objectName..".h\n=================================")
