#version 410 core
layout (triangles) in;
layout (triangle_strip, max_vertices = 24) out;

in VS_OUT {
    vec3 FragPos;
    vec3 Normal;
    vec2 TexCoords;
    mat4 Model;
} gs_in[];

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoords;
out float IsDecorationVertex;

uniform float time;
uniform int isNail;
uniform mat4 view;
uniform mat4 projection;

// Calculate triangle normal
vec3 GetNormal()
{
    vec3 a = vec3(gl_in[0].gl_Position) - vec3(gl_in[1].gl_Position);
    vec3 b = vec3(gl_in[2].gl_Position) - vec3(gl_in[1].gl_Position);
    return normalize(cross(a, b));
}

// Calculate triangle center
vec3 GetCenter()
{
    vec3 center = (vec3(gl_in[0].gl_Position) + 
                   vec3(gl_in[1].gl_Position) + 
                   vec3(gl_in[2].gl_Position)) / 3.0;
    return center;
}

void main() 
{    
    vec3 normal = GetNormal();
    vec3 center = GetCenter();
    
    // Determine finger ID based on texture coordinates
    float texX = gs_in[0].TexCoords.x;
    int fingerID = 0;
    
    // Divide texture coordinate range to identify fingers
    if(texX < 0.2) fingerID = 0;       // Thumb
    else if(texX < 0.4) fingerID = 1;  // Index
    else if(texX < 0.6) fingerID = 2;  // Middle
    else if(texX < 0.8) fingerID = 3;  // Ring
    else fingerID = 4;                  // Pinky
    
    // Output original triangle
    for(int i = 0; i < 3; i++)
    {
        gl_Position = projection * view * gl_in[i].gl_Position;
        FragPos = vec3(gs_in[i].Model * vec4(gl_in[i].gl_Position.xyz, 1.0));
        Normal = gs_in[i].Normal;
        TexCoords = gs_in[i].TexCoords;
        IsDecorationVertex = 0.0;
        
        EmitVertex();
    }
    
    EndPrimitive();
    
    // Generate decoration geometry when isNail == 1
    if(isNail == 1)
    {
        // Thumb (fingerID == 0): Vine-like decoration
        if(fingerID == 0)
        {
            // Create vine lines growing from center
            int numVines = 3;
            float vineLength = 0.03 + 0.01 * sin(time);
            
            for(int vine = 0; vine < numVines; vine++)
            {
                float angle = 6.28318 * float(vine) / float(numVines);
                vec3 tangent = normalize(cross(normal, vec3(sin(angle), cos(angle), 0.0)));
                
                // Create wavy vine path
                int segments = 3;
                for(int seg = 0; seg < segments; seg++)
                {
                    float t = float(seg) / float(segments - 1);
                    float wave = sin(time * 2.0 + t * 3.14159) * 0.01;
                    
                    vec3 vinePos1 = center + normal * (t * vineLength) + tangent * wave;
                    vec3 vinePos2 = center + normal * ((t + 0.1) * vineLength) + tangent * (wave + 0.005);
                    
                    // Create quad strip for vine
                    vec4 p1 = vec4(vinePos1 - tangent * 0.001, 1.0);
                    vec4 p2 = vec4(vinePos1 + tangent * 0.001, 1.0);
                    vec4 p3 = vec4(vinePos2 - tangent * 0.001, 1.0);
                    vec4 p4 = vec4(vinePos2 + tangent * 0.001, 1.0);
                    
                    gl_Position = projection * view * p1;
                    FragPos = vec3(gs_in[0].Model * p1);
                    Normal = normal;
                    TexCoords = vec2(0.5, 0.5);
                    IsDecorationVertex = 1.0;
                    EmitVertex();
                    
                    gl_Position = projection * view * p2;
                    FragPos = vec3(gs_in[0].Model * p2);
                    Normal = normal;
                    TexCoords = vec2(0.5, 0.5);
                    IsDecorationVertex = 1.0;
                    EmitVertex();
                    
                    gl_Position = projection * view * p3;
                    FragPos = vec3(gs_in[0].Model * p3);
                    Normal = normal;
                    TexCoords = vec2(0.5, 0.5);
                    IsDecorationVertex = 1.0;
                    EmitVertex();
                    
                    gl_Position = projection * view * p4;
                    FragPos = vec3(gs_in[0].Model * p4);
                    Normal = normal;
                    TexCoords = vec2(0.5, 0.5);
                    IsDecorationVertex = 1.0;
                    EmitVertex();
                    
                    EndPrimitive();
                }
            }
        }
        else
        {
            // Other fingers: Original pyramid decoration
            float growthFactor = sin(time) * 0.02;
            vec4 tipVertex = vec4(center + normal * growthFactor, 1.0);
            
            for(int face = 0; face < 3; face++)
            {
                int v1 = face;
                int v2 = (face + 1) % 3;
                
                gl_Position = projection * view * gl_in[v1].gl_Position;
                FragPos = vec3(gs_in[v1].Model * vec4(gl_in[v1].gl_Position.xyz, 1.0));
                Normal = normal;
                TexCoords = gs_in[v1].TexCoords;
                IsDecorationVertex = 1.0;
                EmitVertex();
                
                gl_Position = projection * view * gl_in[v2].gl_Position;
                FragPos = vec3(gs_in[v2].Model * vec4(gl_in[v2].gl_Position.xyz, 1.0));
                Normal = normal;
                TexCoords = gs_in[v2].TexCoords;
                IsDecorationVertex = 1.0;
                EmitVertex();
                
                gl_Position = projection * view * tipVertex;
                FragPos = vec3(gs_in[0].Model * vec4(tipVertex.xyz, 1.0));
                Normal = normal;
                TexCoords = vec2(0.5, 0.5);
                IsDecorationVertex = 1.0;
                EmitVertex();
                
                EndPrimitive();
            }
        }
    }
}