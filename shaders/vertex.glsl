#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;

// Interface block to send data to Geometry Shader
out VS_OUT {
    vec3 normal;
    vec2 texCoords;
    vec3 fragPos; // Optional: World space position
} vs_out;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    // Pass data to Geometry Shader
    vs_out.normal = mat3(transpose(inverse(model))) * aNormal;
    vs_out.texCoords = aTexCoords;
    vs_out.fragPos = vec3(model * vec4(aPos, 1.0));

    // We don't apply projection here if we want to do calculations in World/View space in GS
    // But usually, we output gl_Position in Clip Space or View Space.
    // For the 'explode' effect in GS, it's often easier to work in View or Clip space, 
    // or pass gl_Position as View Space and apply Projection in GS.
    // Let's stick to the standard: gl_Position is Clip Space.
    // However, the playbook says "explode" uses normal. 
    // If we explode in Clip Space, it might look weird. 
    // Let's pass gl_Position as View Space or Model Space to GS.
    
    // Standard approach:
    gl_Position = projection * view * model * vec4(aPos, 1.0);
}
