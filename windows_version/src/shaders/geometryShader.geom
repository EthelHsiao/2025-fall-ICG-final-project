#version 330 core
layout (triangles) in;
layout (triangle_strip, max_vertices = 64) out;

in vec2 TexCoord[];
in vec3 RawPos[];

out vec2 gTexCoord;
out vec3 gRawPos;
out float isPattern;
out float shouldColor; 

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform int activeFinger;
uniform float patternProgress;
uniform int showPattern;
uniform int fingerPainted[6];

int getFingerFromUV(vec2 uv) {
    if (uv.y > 0.8) { // 簡化判斷
        if (uv.x < 0.2) return 1;
        else if (uv.x < 0.4) return 2;
        else if (uv.x < 0.6) return 3;
        else if (uv.x < 0.8) return 4;
        return 5;
    }
    return 0; 
}

void emitVertex(vec3 pos, vec2 uv, float pattern, float color) {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    gTexCoord = uv;
    gRawPos = pos;
    isPattern = pattern;
    shouldColor = color;
    EmitVertex();
}

void main() {
    vec2 centerUV = (TexCoord[0] + TexCoord[1] + TexCoord[2]) / 3.0;
    vec3 centerRaw = (RawPos[0] + RawPos[1] + RawPos[2]) / 3.0;
    int fingerIdx = getFingerFromUV(centerUV);

    // 1. 輸出原始模型三角形
    for (int i = 0; i < 3; i++) {
        int vFinger = getFingerFromUV(TexCoord[i]);
        // 判斷該頂點是否應該上色：已被畫過 OR 正在畫
        float colorStatus = (fingerPainted[vFinger] == 1 || (activeFinger == vFinger)) ? 1.0 : 0.0;
        emitVertex(RawPos[i], TexCoord[i], 0.0, colorStatus);
    }
    EndPrimitive();

    // 2. 只有正在裝飾且在指甲區域才生成花紋
    bool isNail = (centerUV.y > 0.85);
    if (showPattern > 0 && isNail && activeFinger == fingerIdx && patternProgress > 0.05) {
        float hash = fract(sin(dot(centerUV, vec2(12.9898, 78.233))) * 43758.5453);
        if (hash < 0.15) { // 控制花紋密度
            float r = 0.02 * patternProgress; // 花紋隨進度變大
            int seg = 6;
            for (int i = 0; i <= seg; i++) {
                float a = float(i) * 6.28318 / float(seg);
                // 在物件空間稍微浮起一點點 (Normal 方向)，避免 Z-fighting
                vec3 offset = vec3(cos(a) * r, 0.0, sin(a) * r);
                emitVertex(centerRaw + offset, centerUV, 1.0, 1.0);
            }
            EndPrimitive();
        }
    }
}