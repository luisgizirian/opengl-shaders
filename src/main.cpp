#include <SDL2/SDL.h>
#include <glad/glad.h>
#include <iostream>
#include <fstream>
#include <string>

// Shader source code
const char* vertexShaderSource = R"(
    #version 410 core
    layout (location = 0) in vec3 position;
    void main()
    {
        gl_Position = vec4(position, 1.0);
    }
)";

std::string LoadShadersAsString(const std::string& filename) {
    // Resulting shader program loaded from file as a single string
    std::string result = "";

    // Open file
    std::string line = "";
    std::ifstream shaderFile(filename);

    if (shaderFile.is_open()) {
        while (getline(shaderFile, line)) {
            result += line + "\n";
        }
        shaderFile.close();
    } else {
        std::cout << "Unable to open file: " << filename << std::endl;
        exit(1);
    }

    return result;
}

int main()
{
    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        std::cerr << "Failed to initialize SDL" << std::endl;
        return -1;
    }

    // SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    // SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    // Create a window
    SDL_Window* window = SDL_CreateWindow("OpenGL Shader", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 800, 600, SDL_WINDOW_OPENGL);
    if (!window)
    {
        std::cerr << "Failed to create SDL window" << std::endl;
        SDL_Quit();
        return -1;
    }

    // Create an OpenGL context
    SDL_GLContext glContext = SDL_GL_CreateContext(window);
    if (!glContext)
    {
        std::cerr << "Failed to create OpenGL context" << std::endl;
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    // Initialize GLAD
    if (!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
    {
        std::cerr << "Failed to initialize GLAD" << std::endl;
        SDL_GL_DeleteContext(glContext);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return -1;
    }

    // Compile and link shaders
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, nullptr);
    glCompileShader(vertexShader);

    // std::string fragmentShaderSource = LoadShadersAsString("shaders/raymarching-full.glsl");
    // std::string fragmentShaderSource = LoadShadersAsString("shaders/plane.glsl");
    std::string fragmentShaderSource = LoadShadersAsString("shaders/corridor.glsl");
    const char* fragmentShaderSourcePtr = fragmentShaderSource.c_str();

    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourcePtr, nullptr);
    glCompileShader(fragmentShader);

    // Check for compilation errors
    GLint success;
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        GLchar infoLog[512];
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cerr << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    // Create a vertex buffer object (VBO)
    float vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f
    };

    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // Define a time constant with the transcurred seconds
    float time = 0.0f;

    // Main loop
    bool quit = false;
    while (!quit)
    {
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            if (event.type == SDL_QUIT)
            {
                quit = true;
            }
            // if Q is pressed, quit
            if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_q)
            {
                quit = true;
            }
        }

        // Capture the mouse position
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);

        // Update time
        time += 0.01f;

        // Clear the screen
        glClear(GL_COLOR_BUFFER_BIT);

        // Use the shader program
        glUseProgram(shaderProgram);

        // Set the time uniform
        glUniform1f(glGetUniformLocation(shaderProgram, "u_Time"), time);
        
        // Pass the window resolution as a vec2 uniform
        glUniform2f(glGetUniformLocation(shaderProgram, "u_Resolution"), 800.0f, 600.0f);

        // Pass the mouse position as a vec2 uniform
        glUniform2f(glGetUniformLocation(shaderProgram, "u_Mouse"), mouseX, mouseY);

        // Bind the VBO
        glBindBuffer(GL_ARRAY_BUFFER, VBO);

        // Set the vertex attribute pointers
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);

        // Draw the quad
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        // Configure to run at measured FPS
        SDL_GL_SetSwapInterval(1);

        // Swap buffers
        SDL_GL_SwapWindow(window);
    }

    // Clean up
    glDeleteProgram(shaderProgram);
    glDeleteShader(fragmentShader);
    glDeleteShader(vertexShader);
    glDeleteBuffers(1, &VBO);

    // Destroy OpenGL context and window
    SDL_GL_DeleteContext(glContext);
    SDL_DestroyWindow(window);

    // Quit SDL
    SDL_Quit();

    return 0;
}
