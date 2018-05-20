# wavefront64


![Celebi](https://i.imgur.com/fXzqiGc.gif)


### Usage:
`./Wavefront64 your_obj_file.obj <scale> <use gsSP1Triangle>`

Vertex Scale argument defaults to 30
Fast3D argument defaults to false

e.g. `./Wavefront64 Celebi.obj 30`

However if you want to help with this project and want to run
the development version, replace `./Wavefront64` with `lua main.lua` 
e.g. `lua main.lua Celebi.obj 30`

Outputs to a C header file of the same name.
e.g. `Celebi.h`	


### Limitations:
* Textures must be BITMAP files
* Textures must be 32x32 pixels at most
* can only handle a single mesh, no matter how many verts

I will be actively working on fixing these limitations after exam season is over!