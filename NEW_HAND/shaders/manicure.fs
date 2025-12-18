#version 410 core
out vec4 FragColor;

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;
in float IsDecorationVertex;

uniform sampler2D texture_diffuse1;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform float time;

void main()
{
    vec3 normal = normalize(Normal);
    
    // Get texture color
    vec3 texColor = texture(texture_diffuse1, TexCoords).rgb;
    if(length(texColor) < 0.01) {
        texColor = vec3(0.9, 0.8, 0.7);  // Light skin color
    }
    
    // Multiple light sources for better depth
    vec3 viewDir = normalize(viewPos - FragPos);
    
    // Main light
    vec3 lightDir1 = normalize(lightPos - FragPos);
    float diff1 = max(dot(normal, lightDir1), 0.0);
    vec3 reflectDir1 = reflect(-lightDir1, normal);
    float spec1 = pow(max(dot(viewDir, reflectDir1), 0.0), 32.0);
    
    // Fill light (softer, from opposite side)
    vec3 fillLightPos = vec3(-lightPos.x, lightPos.y * 0.5, lightPos.z);
    vec3 lightDir2 = normalize(fillLightPos - FragPos);
    float diff2 = max(dot(normal, lightDir2), 0.0);
    
    // Rim light for edge definition
    float rimPower = 1.0 - max(dot(viewDir, normal), 0.0);
    rimPower = pow(rimPower, 3.0);
    vec3 rimColor = vec3(0.3, 0.3, 0.4) * rimPower;
    
    // Combine lighting
    vec3 ambient = vec3(0.25) * texColor;  // Reduced ambient for more contrast
    vec3 diffuse = (diff1 * 0.7 + diff2 * 0.3) * texColor;
    vec3 specular = spec1 * vec3(0.4);
    
    vec3 color = ambient + diffuse + specular + rimColor;
    
    // Add special effect for decoration vertices
    if(IsDecorationVertex > 0.5)
    {
        // Metallic/diamond effect for nail decoration
        float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 2.0);
        vec3 iridescent = vec3(
            0.5 + 0.5 * sin(time * 2.0 + fresnel * 10.0),
            0.5 + 0.5 * sin(time * 2.0 + fresnel * 10.0 + 2.094),
            0.5 + 0.5 * sin(time * 2.0 + fresnel * 10.0 + 4.188)
        );
        color = color * 0.3 + iridescent * 0.7 + specular * 2.0;
    }
    
    FragColor = vec4(color, 1.0);
}