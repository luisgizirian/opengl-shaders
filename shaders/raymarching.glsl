#version 410 core

uniform float u_Time;
uniform vec2 u_Resolution;
uniform vec2 u_Mouse;

out vec4 FragColor;

const float FOV = 1.0;
const int MAX_STEPS = 256;
const float MAX_DIST = 500.f;
const float EPSILON = 0.001f;
const float PI = 3.14159265f;
const float TAU = (2*PI);

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
	return dot(p, n) + distanceFromOrigin;
}

float fSphere(vec3 p, float r) {
    return length(p) - r;
}

void pMod3(inout vec3 p, vec3 size) {
    p = mod(p, size) - size * 0.5;
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

vec2 fOpUnionID(vec2 res1, vec2 res2) {
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 map(vec3 p) {
    // plane
    float planeDist = fPlane(p, vec3(0,1,0), 1.0);
    float planeID = 2.0;
    vec2 plane = vec2(planeDist, planeID);
    // sphere
    float sphereDist = fSphere(p, 1.0);
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist, sphereID);
    // result
    vec2 res = fOpUnionID(sphere, plane);
    return res;
}

vec2 rayMarch(vec3 ro, vec3 rd) {
    vec2 hit, object;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + object.x * rd;
        hit = map(p);
        object.x += hit.x;
        object.y = hit.y;
        if (abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
    }
    return object;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
    return normalize(n);
}

vec3 getLight(vec3 p, vec3 rd, vec3 color) {
    vec3 lightPos = vec3(20.0, 40.0, -30.0);
    vec3 L = normalize(lightPos - p);
    vec3 N = getNormal(p);
    // improve object shading
    vec3 V = -rd;
    vec3 R = reflect(-L, N);

    vec3 specColor = vec3(0.5);
    vec3 specular = specColor * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
    vec3 diffuse = color * clamp(dot(L, N), 0.0, 1.0);
    vec3 ambient = color * 0.05;

    // shadows
    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    if (d < length(lightPos - p)) return ambient;
    
    return diffuse + ambient + specular;
}

vec3 getMaterial(vec3 p, float id) {
    vec3 m;
    switch (int(id)) {
        case 1:
            m = vec3(0.9, 0.0, 0.0);
            break;
        case 2:
            m = vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0));
            break;
    }
    return m;
}

mat3 getCam(vec3 ro, vec3 lookAt) {
    vec3 camF = normalize(vec3(lookAt - ro));
    vec3 camR = normalize(cross(vec3(0.0, 1.0, 0.0), camF));
    vec3 camU = cross(camF, camR);
    return mat3(camR, camU, camF);
}

void mouseControl(inout vec3 ro) {
    vec2 m = u_Mouse / u_Resolution;
    pR(ro.yz, m.y * PI * 0.5 - 0.5);
    pR(ro.xz, m.x * TAU);
}

void render(inout vec3 col, in vec2 uv) {
    vec3 ro = vec3(3.0, 3.0, -3.0);
    mouseControl(ro);
    
    vec3 lookAt = vec3(0.0, 0.0, 0.0);
    vec3 rd = getCam(ro, lookAt) * normalize(vec3(uv, FOV));
    
    vec2 object = rayMarch(ro, rd);

    vec3 background = vec3(0.5, 0.8, 0.9);
    if (object.x < MAX_DIST) {
        vec3 p = ro + object.x * rd;
        vec3 material = getMaterial(p, object.y);
        col += getLight(p, rd, material);
        // fog
        col = mix(col, background, 1.0 - exp(-0.0008 * object.x * object.x));
    } else {
        col += background - max(0.95 * rd.y, 0.0);
    }
}

void main() {
    vec2 uv = (2.0 * gl_FragCoord.xy - u_Resolution) / u_Resolution.y;

    vec3 col;
    render(col, uv);

    // gamma correction
    col = pow(col, vec3(0.4545));
    FragColor = vec4(col, 1.0);
}