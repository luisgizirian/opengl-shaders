# Playground on Computer Graphics Shaders on OpenGL
This time using OpenGL, SDL2 and others.

## Run
A Linux system, even a WSL2 (if you're on a modern Windows system), will do.

### Prereqs
- SDL2 -Simple DirectMedia Layer (https://www.libsdl.org/)

`sudo apt-get install libsdl2-dev`

### Compilation pipeline
`g++ -std=c++17 ./src/*.cpp -o prog -lSDL2 -ldl -I ./include/`

### Finally, run the program
`./prog`

## Sources
All samples slightly modidified to work under C++ and SDL2

- Kishimisu "An Introduction to Shader Art Coding" (https://www.youtube.com/watch?v=f4s1h2YETNY) using C++ and GLAD at `/shaders/frag.glsl`
- Coder Space "Procedural 3D Engine, Ray Mrching OpenGL Tutorial" (https://www.youtube.com/watch?v=hUaYxqkrfjA) at `/shaders/raymarching-full.glsl` and `/shaders/raymarching.glsl`
- `hf_sdf` GLSL Library (https://mercury.sexy/hg_sdf)
- NuSan "Corridor Travel" (https://www.shadertoy.com/view/3sXyRN) `/shaders/corridor.glsl`
- Coder Space "The Planet Sine" (https://www.youtube.com/watch?v=u1pRapBEHlU) at `/shaders/plane.glsl`

## Related material

- Mike Shah Channel: https://www.youtube.com/@MikeShah
- https://www.shadertoy.com/
- Inigo Quilez Channel: https://www.youtube.com/channel/UCdmAhiG8HQDlz8uyekw4ENw