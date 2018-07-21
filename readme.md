# Wavefront64


![Celebi](https://i.imgur.com/fXzqiGc.gif)


### Usage:
```bash
lua main.lua <operation> <file>
```

Operations:
* obj (converts textured wavefront to C header)
* spr (converts bitmap to C header)

Preparation:
* Remember to *triangulate* your object first before exporting to .obj!

#### Examples
OBJ -> C
`lua main.lua obj <path_to_obj>`
e.g. `lua main.lua obj Celebi.obj`

SPRITE -> C
`lua main.lua spr <path_to_bmp>`
e.g. `lua main.lua spr Celebi.bmp`

Outputs to a C header file of the same name.
e.g. `Celebi.h`	

### Requirements:
* Lua
* Computer

### Limitations:
* **Does not work with vertex colours**, .obj files dont export that data!
* Textures must be BITMAP files
* Textures must be 32x32 pixels at most
* can only handle a single mesh

I will be actively working on fixing these limitations after exam season is over!

### Todo:
* ~~Add functionality to just parse images for sprites!~~
* Add PNG support for said features
* Let objects have more than one texture
