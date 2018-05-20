bitmap = require("bitmap")
obj_loader = require("obj_loader")
require("BinDecHex")
require("util")
helptext = [[

WAVEFRONT 64
============

Usage:
	"lua main.lua your_obj_file.obj <scale> <use gsSP1Triangle>"
	
	Vertex Scale argument defaults to 30
	Fast3D argument defaults to false
	
	e.g. `lua main.lua Celebi.obj 30`

Outputs to a C header file of the same name.
e.g. `Celebi.h`	

Please note that this currently only works with objects that:
* have only a single mesh
* have one bitmap texture with a max size of 32x32

]]
--[[ 
==========================
 PARAMETERS
==========================
--]] 

final_file_output = {}
two_tris = not arg[3] or false
object_scale = arg[2] or 30

--[[ 
==========================
 PARAMETERS
==========================
--]] 
if(arg[1]==nil) then
	print(helptext)
	err()
end

print("Object Scale set to "..object_scale)
print("Fast3D on: "..tostring(not two_tris))


obj_Name = string.match(arg[1], "([A-Za-z0-9]+)")

mtl_file = readFile(obj_Name..".mtl")
if(mtl_file == nil) then err("ERROR: No MTL file found for "..obj_Name..".mtl") else print("MTL file "..obj_Name..".mtl found.") end

-- init object
obj_Table = obj_loader.load(obj_Name..".obj")
if(obj_Table==nil) then
	err(obj_Name..".obj not found")
else
	print("OBJ File "..obj_Name..".obj found.")
end

-- init bitmap
image_file_name, name_of_texture = string.match(mtl_file, "map_Kd (([A-Za-z_-]+).[A-Za-z_-]+)")
bmp = bitmap.from_file(image_file_name)
if(bmp==nil) then
	err("ERROR: File "..image_file_name.." doesn't exist, or file isn't a bitmap")
else
	print("BMP File "..image_file_name.." found.")
end



--[[ 
====================================
 BITMAP PARSING TO BIG HEX-Y CHUNKS
====================================
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
		table.insert(table_preview,preview_tokens[math.floor((((r+g+b)/(255*3))*#preview_tokens))+1])

		local binstring = padBinaryLeft(intToBin(math.floor(r/8)),5)..
			padBinaryLeft(intToBin(math.floor(g/8)),5)..
			padBinaryLeft(intToBin(math.floor(b/8)),5).."1"

		local outstring = "0x"..string.lower(Bin2Hex(binstring))..","
		if(j==bmp.height-1) then outstring = "\t"..outstring end
		if(j==0) then outstring = outstring.."\n" end
		table.insert(table_of_bytes,outstring)
	end
end
print("Success parsing bitmap!")
-- PREVIEW AND METADATA
appendToOutput("/*\nObject Name: "..obj_Name.."\nObject Scaling Factor: "..object_scale.."\n\nTexture preview:"..table.concat(table_preview).."\n*/")
-- DATA
appendToOutput("unsigned short Text_"..obj_Name.."_"..name_of_texture.."_diff[] = {\n"..table.concat(table_of_bytes).."};")


--[[ 
======================================
 FACES AND VERTS OUTPUT
======================================

TABLE STRUCTURES REFERENCE
==========================
vertexTable {
	"3/5":
		"index": 4
		"content": "{ 30, -30, 30, 0, 0, 990, 130, 130, 130, 0},"
	"4/6"
		"index": 5 
		...

faceTable {
	1: {2,5,3}
	2: {4,0,2}
	3: ...

--]] 

print("Creating faces and verts...")

faceTable = {}
vertexTable = {}
vertexOutputTable = {}
vertsCreated = 0

function formatVert(floatString)
	return padStringLeft(math.floor(object_scale*floatString),5)
end

-- generate faces and verts arrays
for i=1,#obj_Table.f do
	local faceVertReference = {}
	for j=1,3 do
		-- "4/6", etc
		local vert_ref_string = string.format("%i/%i",obj_Table.f[i][j].v,obj_Table.f[i][j].vt)

		-- if the vertex DOESN'T already exist within a table, then create and assign it
		if(vertexTable[vert_ref_string] == nil) then
			--[[ 
				make vert STRING for THIS unique combination
				TODO: change 130 to the actual vert colors (if any)
			--]] 
			local vertString = string.format(
				"\t{%s, %s, %s, 0, %s, %s, 130, 130, 130, 0}, //id: %i",
				-- output spacial coordinates
				formatVert( obj_Table.v[obj_Table.f[i][j].v].x ),
				formatVert( obj_Table.v[obj_Table.f[i][j].v].y ),
				formatVert( obj_Table.v[obj_Table.f[i][j].v].z ),
				-- output texture coordinates
				padStringLeft(math.floor(2*object_scale*(bmp.height+1)*obj_Table.vt[obj_Table.f[i][j].vt].v),6),
				padStringLeft(math.floor(2*object_scale*(bmp.width+1)*obj_Table.vt[obj_Table.f[i][j].vt].u),6),
				vertsCreated
			)

			-- put vertex in vertexTable
			-- At the index, eg. "3/6" (vertex 3, tex vertex 6) create a unique vert
			vertexTable[vert_ref_string] = {
				index = vertsCreated,
				content = vertString
			}

			faceVertReference[j] = vertexTable[vert_ref_string].index
			vertsCreated = vertsCreated + 1
			if(vertexTable[vert_ref_string].content ~= nil) then
				table.insert(vertexOutputTable,vertexTable[vert_ref_string].content)
			end
		else
		-- else, just assign the already-existing vertex
			faceVertReference[j] = vertexTable[vert_ref_string].index
		end
	end
	faceTable[i] = {faceVertReference[1],faceVertReference[2],faceVertReference[3]}
end


--[[ 
=================================================
 SORT FACES AND VERTS INTO PACKS OF 32, BY INDEX
=================================================

TABLE STRUCTURES REFERENCE
==========================
facesPackRefs {
	1: { 1, 2, 3...30,31,32}
	2: {33,34,35...62,63,64}
	...

facesInPacks {
	1:
		1: {2,5,3}
		2: {4,0,2}
	2:
		1: ...

--]] 

-- withholds the actual vert / face STRINGS per pack
facesInPacks = {}
facesNotInPacks = {}
-- small buffer to check which references are in each pack
facesPackRefs = {}

--[[ 
MAIN PACKAGING ALGORITHM
=========================

for all verts
	loop through packs until:
		current pack allows for additional vert eg. (0,1,2)
		32 - [length of current pack] - [verts not already in pack] > 0
		then
			insert face into current pack
	endloop
endfor

Hopefully this accomodates for verts that are close together in an actual object, otherwise
it won't be very optimised in terms of memory, but it'll still work.
--]] 


local packerrors = 0
for i=1, #faceTable do
	local inserted = false
	for j=1,10 do
		local unique_references = {}
		-- if pack doesn't exist yet, create it
		if(type(facesPackRefs[j]) ~= "table") then
			facesInPacks[j] = {}
			facesPackRefs[j] = {}
		end
		-- count up the amount of unique references that already exist in the current pack
		for h=1,3 do
			if(not inTable(facesPackRefs[j], faceTable[i][h]+1)) then
				table.insert(unique_references,faceTable[i][h]+1)
			end
		end
		-- if they can fit in the pack, put it in
		if(32 - #facesPackRefs[j] - #unique_references >= 0) then
			for z=1, #unique_references do
				table.insert(facesPackRefs[j],unique_references[z])
			end
			table.insert(facesInPacks[j],faceTable[i])
			inserted = true
			break;
		end
	end
	-- WE DON'T WANT THIS!! BUT IT'S HERE JUST IN CASE
	if(inserted==false) then
		packerrors = packerrors + 1
		table.insert(facesNotInPacks,faceTable[i])
		printf("Face (%i, %i, %i) can't be put into a pack!",faceTable[i][1],faceTable[i][2],faceTable[i][3])
	end
end


if(packerrors>0) then
	err("BUILD FAIL: "..packerrors.." faces weren't able to be consecutively referenced. Cancelling build.")
end


-- output verts in their packs
vertexRefs = {}
for packNumber=1, #facesPackRefs do
	local vertPrintTable = {}
	for i=1,#facesPackRefs[packNumber] do
		table.insert(vertPrintTable,vertexOutputTable[facesPackRefs[packNumber][i]]..", direct reference: ["..(packNumber-1).."]["..(i-1).."]")
	end
	appendToOutput("Vtx_tn Vtx_"..obj_Name.."_mesh01_"..(packNumber-1).."["..#facesPackRefs[packNumber].."] = {\n"..table.concat(vertPrintTable,"\n").."\n};")
end


function getLocationOfItem(haystack,needle)
	for i=1,#haystack do
		if(haystack[i] == needle) then
			return i
		end
	end
	return false
end

-- WRITE FACES TO FILE / DISPLAY LIST
faceOutputTable = {}
for packNumber=1,#facesInPacks do
	if(#facesInPacks[packNumber] > 0) then
		table.insert(faceOutputTable,"gsSPVertex(&Vtx_"..obj_Name.."_mesh01_"..(packNumber-1).."[0], "..#facesPackRefs[packNumber]..", 0)")
	end
	local step = 0
	if(two_tris) then step = 2 else step = 1 end
	for k=1,#facesInPacks[packNumber], step do
		if(#facesInPacks[packNumber] - k > 0 and two_tris) then
			table.insert(
				faceOutputTable,
				string.format(
					"gsSP2Triangles(%i,%i,%i,0,%i,%i,%i,0)",
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][1]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][2]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][3]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k+1][1]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k+1][2]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k+1][3]+1)-1
				)
			)
		else
			table.insert(
				faceOutputTable,
				string.format(
					"gsSP1Triangle(%i,%i,%i,0)",
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][1]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][2]+1)-1,
					getLocationOfItem(facesPackRefs[packNumber], facesInPacks[packNumber][k][3]+1)-1
				)
			)
		end
	end
end
-- output faces
appendToOutput("Gfx Vtx_"..obj_Name.."_mesh01_dl[] = {\n\t"..table.concat(faceOutputTable,",\n\t")..",\n\tgsSPEndDisplayList(),\n};")
print("Success creating faces and verts!")




-- output final display list
-- This isn't customisable at the moment at all but until I actually figure out what'd need changing, I'll leave this!
appendToOutput(
	"Gfx Wtx_"..obj_Name.."[] = {\n\tgsDPLoadTextureBlock(Text_"..obj_Name.."_"..name_of_texture..
	"_diff, G_IM_FMT_RGBA, G_IM_SIZ_16b,\n\t\t32,32, 0, G_TX_WRAP|G_TX_NOMIRROR, G_TX_WRAP|G_TX_NOMIRROR,\n\t\t5,5, G_TX_NOLOD, G_TX_NOLOD),\n\tgsSPDisplayList(Vtx_"
	..obj_Name.."_mesh01_dl),\n\tgsSPEndDisplayList()\n};"
)

file = io.open(obj_Name..".h","w")
io.output(file)
io.write(table.concat(final_file_output,"\n\n"))
io.close(file)

print("=================================\nDONE!\nOutput file: \n"..obj_Name..".h\n=================================")
