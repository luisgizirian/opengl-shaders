#version 410 core

uniform float iTime;

out vec4 FragColor;

void main() {
    float lineWidth = 0.02; // Width of the line
    float speed = 0.5; // Speed of the line
    float t = abs(fract(iTime * speed + 0.5) * 2.0 - 1.0); // Triangle wave function
    float linePos = t * (1.0 - 2.0 * lineWidth) + lineWidth; // Position of the line

    if (abs(gl_FragCoord.x / 800.0 - linePos) <= lineWidth) {
        FragColor = vec4(1.0, 0.0, 0.0, 1.0); // Red line
    } else {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black background
    }
}