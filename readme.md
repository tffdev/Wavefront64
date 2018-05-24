# Wavefront64


![Celebi](https://i.imgur.com/fXzqiGc.gif)


### Usage:
`lua main.lua your_obj_file.obj`

Vertex Scale argument defaults to 30
Fast3D argument defaults to false

e.g. `lua main.lua Celebi.obj`

The script will ask you what you want vertex scaling to be and if you want Fast3D support.

Outputs to a C header file of the same name.
e.g. `Celebi.h`	

### Requirements:
* `Lua` >= 5.2 (I guess)
OR (better)
* `luajit`, `sudo apt-get install luajit` and replace `lua` with `luajit` when running script.

### Limitations:
* Textures must be BITMAP files
* Textures must be 32x32 pixels at most
* can only handle a single mesh, no matter how many verts

I will be actively working on fixing these limitations after exam season is over!

### Todo:
* Add functionality to just parse images for sprites!
* Add PNG support for said features
* Let objects have more than one texture