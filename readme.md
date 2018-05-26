# Wavefront64


![Celebi](https://i.imgur.com/fXzqiGc.gif)


### Usage:
`lua main.lua <operation> <file>`

Operations:
* obj (converts textured wavefront to C header)
* spr (converts bitmap to C header)

#### Examples
OBJ -> C
`lua main.lua obj <path_to_obj>`
e.g. `lua main.lua obj Celebi.obj`

SPRITE -> C
`lua main.lua spr <path_to_bmp>`
e.g. `lua main.lua spr Celebi.bmp`

Outputs to a C header file of the same name.
e.g. `Celebi.h`	


Vertex Scale argument defaults to 30
Fast3D argument defaults to false

The script will ask you what you want vertex scaling to be and if you want Fast3D support.

### Requirements:
* Lua
* Computer

### Limitations:
* Textures must be BITMAP files
* Textures must be 32x32 pixels at most
* can only handle a single mesh, no matter how many verts

I will be actively working on fixing these limitations after exam season is over!

### Todo:
* Add functionality to just parse images for sprites!
* Add PNG support for said features
* Let objects have more than one texture