#version 410 core

uniform float iTime;

out vec4 FragColor;

void main() {
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.05;
    // Modify the x position of the circle to create a bouncing effect
    vec2 position = vec2(radius + ((sin(iTime * 2.0) + 1.0) / 2.0) * (1.0 - 2.0 * radius), center.y);
    
    float distance = length(gl_FragCoord.xy / vec2(800.0, 600.0) - position);
    if (distance <= radius) {
        FragColor = vec4(0.0, 1.0, 0.0, 1.0); // Green circle
    } else {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black background
    }
}