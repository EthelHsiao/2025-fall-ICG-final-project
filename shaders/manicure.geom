#version 330 core
layout (triangles) in;
layout (triangle_strip, max_vertices = 12) out;

in VS_OUT {
    vec3 normal;
    vec2 texCoords;
    vec3 fragPos;
} gs_in[];

out vec2 TexCoords;
out vec3 Normal;

vec3 GetNormal() {
    // Calculate face normal from the 3 vertices of the triangle
    // Note: These positions are in Clip Space (or whatever VS output)
    vec3 a = vec3(gl_in[0].gl_Position) - vec3(gl_in[1].gl_Position);
    vec3 b = vec3(gl_in[2].gl_Position) - vec3(gl_in[1].gl_Position);
    return normalize(cross(a, b));
}

vec4 explode(vec4 position, vec3 normal) {
    // Static function - no animation
    return position;
}

void main() {
    vec3 normal = GetNormal();

    // Task 3.1: Basic GS Copy / Explode
    // Emit the original triangle, but displaced
    for(int i = 0; i < 3; i++) {
        // gl_Position = explode(gl_in[i].gl_Position, normal); // Animation disabled
        gl_Position = gl_in[i].gl_Position; // Static position
        TexCoords = gs_in[i].texCoords;
        Normal = gs_in[i].normal; // Or use the calculated face 'normal'
        EmitVertex();
    }
    EndPrimitive();

    // Task 3.2 & 3.3: Generate Decoration (Example: A spike or second layer)
    // This is a placeholder for the advanced part.
    // You would calculate a center point, add a new vertex, and create new primitives.
    /*
    vec4 center = (gl_in[0].gl_Position + gl_in[1].gl_Position + gl_in[2].gl_Position) / 3.0;
    vec4 spikeTip = explode(center, normal * 2.0); // Push further out
    
    // Create a pyramid or spike
    // ... EmitVertex calls ...
    // EndPrimitive();
    */
}
