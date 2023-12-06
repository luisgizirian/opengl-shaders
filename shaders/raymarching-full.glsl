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

// Sign function that doesn't return 0
float sgn(float x) {
	return (x<0)?-1:1;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0)?-1:1, (v.y<0)?-1:1);
}

// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
	return min(v.x, v.y);
}

float vmin(vec3 v) {
	return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
	return min(min(v.x, v.y), min(v.z, v.w));
}




////////////////////////////////////////////////////////////////
//
//             PRIMITIVE DISTANCE FUNCTIONS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that is a distance function is called fSomething.
// The first argument is always a point in 2 or 3-space called <p>.
// Unless otherwise noted, (if the object has an intrinsic "up"
// side or direction) the y axis is "up" and the object is
// centered at the origin.
//
////////////////////////////////////////////////////////////////

float fSphere(vec3 p, float r) {
	return length(p) - r;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
	return dot(p, n) + distanceFromOrigin;
}

// Cheap Box: distance to corners is overestimated
float fBoxCheap(vec3 p, vec3 b) { //cheap box
	return vmax(abs(p) - b);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Same as above, but in two dimensions (an endless box)
float fBox2Cheap(vec2 p, vec2 b) {
	return vmax(abs(p)-b);
}

float fBox2(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}


void pMod3(inout vec3 p, vec3 size) {
    p = mod(p, size) - size * 0.5;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/n/2.0;
		columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2)/2*r;
		p.x += -columnradius*sqrt(2)/2;

		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

float fDisplace(vec3 p) {
    pR(p.yz, sin(2.0 * u_Time));
    return (sin(p.x + 4.0 * u_Time) * sin(p.y + sin(2.0 * u_Time)) * sin(p.z + 6.0 * u_Time));
}

// The "Chamfer" flavour makes a 45-degree chamfered edge (the diagonal of a square of size <r>):
float fOpUnionChamfer(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2 * s)) - s)));
}

vec2 fOpUnionID(vec2 res1, vec2 res2) {
    return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1, vec2 res2) {
    return (res1.x > -res2.x) ? res1 : vec2(-res2.x, res2.y);
}

vec2 fOpDifferenceColumnsID(vec2 res1, vec2 res2, float r, float n) {
    float dist = fOpDifferenceColumns(res1.x, res2.x, r, n);
    return (res1.x > -res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionStairsID(vec2 res1, vec2 res2, float r, float n) {
    float dist = fOpUnionStairs(res1.x, res2.x, r, n);
    return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionChamferID(vec2 res1, vec2 res2, float r) {
    float dist = fOpUnionChamfer(res1.x, res2.x, r);
    return (res1.x < res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 map(vec3 p) {
    // plane
    float planeDist = fPlane(p, vec3(0,1,0), 7);
    float planeID = 2.0;
    vec2 plane = vec2(planeDist, planeID);
    // sphere
    float sphereDist = fSphere(p, 2.25 + fDisplace(p));
    float sphereID = 1.0;
    vec2 sphere = vec2(sphereDist, sphereID);
    // manipulation opertors
    pMirrorOctant(p.xz, vec2(12.5, 12.5));
    p.x = -abs(p.x) + 5;
    pMod1(p.z, 3.75);
    // roof
    vec3 pr = p;
    pr.y -= 3.875;
    pR(pr.xy, 0.6);
    pr.x -= 3;
    float roofDist = fBox2(pr.xy, vec2(5, 0.3));
    float roofID = 4.0;
    vec2 roof = vec2(roofDist, roofID);
    // box
    float boxDist = fBox(p, vec3(0.75, 2.25, 1.0));
    float boxID = 3.0;
    vec2 box = vec2(boxDist, boxID);
    // cylinder
    vec3 pc = p;
    pc.y -= 2.25;
    float cylinderDist = fCylinder(pc.yxz, 1, (2.25 / 3));
    float cylinderID = 3.0;
    vec2 cylinder = vec2(cylinderDist, cylinderID);
    // wall
    float wallDist = fBox2(p.xy, vec2(0.25, 3.75));
    float wallID = 3.0;
    vec2 wall = vec2(wallDist, wallID);
    // result
    vec2 res;
    //res = wall;
    res = fOpUnionID(box, cylinder);
    res = fOpDifferenceColumnsID(wall, res, 0.3, 1.5);
    res = fOpUnionChamferID(res, roof, 0.3);
    res = fOpUnionStairsID(res, plane, 4.0, 5.0);
    res = fOpUnionID(res, sphere);
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
    vec3 fresnel =0.25 * color * pow(1.0 + dot(rd, N), 3.0);

    // shadows
    float d = rayMarch(p + N * 0.02, normalize(lightPos)).x;
    if (d < length(lightPos - p)) return ambient;
    
    return diffuse + ambient + specular + fresnel;
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
        case 3:
            m = vec3(0.7, 0.8, 0.9);
            break;
        case 4:
            vec2 i = step(fract(0.5 * p.xz), vec2(1.0 / 10.0));
            m = ((1.0 - i.x) * (1.0 - i.y)) * vec3(0.37, 0.12, 0.0);
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
    vec3 ro = vec3(9.0, 4.25, -9.0);
    mouseControl(ro);
    
    vec3 lookAt = vec3(0.0, 1.0, 0.0);
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