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
uniform int showPattern;
uniform float patternProgress;
uniform int fingerPainted[6]; // ★ 新增:接收已完成手指的陣列

void emitVertex(vec3 pos, vec2 uv, float pattern) {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    gTexCoord = uv;
    gRawPos = pos;
    isPattern = pattern;
    shouldColor = 1.0;
    EmitVertex();
}

int getFingerIndex(vec2 uv) {
    if (uv.y < 0.1) {
        if (uv.x < 0.5) {
            if (uv.x < 0.1) return 5;
            else if (uv.x < 0.2) return 4;
            else if (uv.x < 0.3) return 3;
            else if (uv.x < 0.4) return 2;
            else return 1;
        } else {
            if (uv.x < 0.6) return 1;
            else if (uv.x < 0.7) return 2;
            else if (uv.x < 0.8) return 3;
            else if (uv.x < 0.9) return 4;
            else return 5;
        }
    }
    return 0;
}

void main() {
    vec2 centerUV = (TexCoord[0] + TexCoord[1] + TexCoord[2]) / 3.0;
    vec3 centerRaw = (RawPos[0] + RawPos[1] + RawPos[2]) / 3.0;

    // 1. 輸出原始三角形
    for (int i = 0; i < 3; i++) {
        emitVertex(RawPos[i], TexCoord[i], 0.0);
    }
    EndPrimitive();

    // 2. 判斷是否要顯示花紋
    int fingerIdx = getFingerIndex(centerUV);
    bool isNailArea = (centerUV.y < 0.1 && centerUV.y > 0.0);
    
    // ★ 關鍵修改:檢查此手指是否已完成或正在生長
    bool isGrowing = (fingerIdx == activeFinger && patternProgress > 0.01);
    bool isFinished = (fingerIdx > 0 && fingerIdx < 6 && fingerPainted[fingerIdx] == 1);
    
    if (showPattern > 0 && isNailArea && (isGrowing || isFinished)) {
        float hash = fract(sin(dot(centerUV, vec2(12.9898, 78.233))) * 43758.5453);
        
        // ★ 根據狀態決定使用的進度值
        float currentProgress = isFinished ? 1.0 : patternProgress;
        
        if (hash < currentProgress * 0.6) {
            float normalizedHash = hash / (currentProgress * 0.3);
            float r = mix(0.08, 0.15, normalizedHash);
            
            vec3 normal = normalize(cross(
                RawPos[1] - RawPos[0],
                RawPos[2] - RawPos[0]
            ));
            vec3 basePos = centerRaw + normal * 0.015;
            
            int seg = 8;
            for (int i = 0; i <= seg; i++) {
                float angle = float(i) * 6.28318 / float(seg);
                vec3 offset = vec3(cos(angle) * r, sin(angle) * r, 0.0);
                emitVertex(basePos + offset, centerUV, 1.0);
            }
            EndPrimitive();
        }
    }
}
