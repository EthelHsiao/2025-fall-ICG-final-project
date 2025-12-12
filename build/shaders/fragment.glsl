#version 330 core
out vec4 FragColor;

in vec2 TexCoords;
in vec3 Normal; // Received from GS

void main()
{
    // Simple lighting or color based on normal
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    float diff = max(dot(norm, lightDir), 0.0);
    
    vec3 objectColor = vec3(0.95, 0.82, 0.7); // Skin color
    
    // Time based color change - DISABLED
    // objectColor.r = (sin(time) + 1.0) / 2.0;

    vec3 diffuse = diff * objectColor;
    vec3 ambient = 0.1 * objectColor;
    
    FragColor = vec4(ambient + diffuse, 1.0);
}
