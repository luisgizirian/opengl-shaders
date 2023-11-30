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
- Kishimisu's "An Introduction to Shader Art Coding" (https://www.youtube.com/watch?v=f4s1h2YETNY) using C++ and GLAD

## Related material

- Mike Shah Channel: https://www.youtube.com/@MikeShah
- https://www.shadertoy.com/