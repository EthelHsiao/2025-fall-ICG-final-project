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
uniform float purplePaintProgress;

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

    // 2. 生成花紋
    int fingerIdx = getFingerIndex(centerUV);
    bool isNailArea = (centerUV.y < 0.1);

    if (showPattern > 0 && isNailArea && fingerIdx == activeFinger && patternProgress > 0.01) {
        float hash = fract(sin(dot(centerUV, vec2(12.9898, 78.233))) * 43758.5453);

        if (hash < 0.25) {
            float r = 0.04 * patternProgress;

            vec3 normal = normalize(cross(
                RawPos[1] - RawPos[0],
                RawPos[2] - RawPos[0]
            ));
            vec3 basePos = centerRaw + normal * 0.003;

            int seg = 8;
            for (int i = 0; i <= seg; i++) {
                float a = float(i) * 6.28318 / float(seg);
                vec3 offset = vec3(cos(a) * r, 0.0, sin(a) * r);
                emitVertex(basePos + offset, centerUV, 1.0);
            }
            EndPrimitive();
        }
    }

    // 3. 紫色閃光效果（P鍵觸發，只在已上色區域顯示）
    if (purplePaintProgress > 0.01 && isNailArea && fingerIdx > 0) {
        // 計算此位置是否已被塗抹（從指尖開始）
        float nailPos = centerUV.y / 0.1;
        nailPos = clamp(nailPos, 0.0, 1.0);
        float paintFront = purplePaintProgress * 1.3;

        // 只在已塗抹的區域生成閃光
        if (nailPos < paintFront + 0.3) {
            float hash2 = fract(sin(dot(centerUV, vec2(78.233, 12.9898))) * 43758.5453);

            // 根據進度逐漸增加閃光密度
            float density = 0.15 * purplePaintProgress;

            if (hash2 < density) {
                vec3 normal = normalize(cross(
                    RawPos[1] - RawPos[0],
                    RawPos[2] - RawPos[0]
                ));
                vec3 basePos = centerRaw + normal * 0.004;

                // 創建小型星形閃光
                float sparkleSize = 0.02 * purplePaintProgress;
                int points = 4;

                for (int i = 0; i < points * 2; i++) {
                    float angle = float(i) * 3.14159 / float(points);
                    float radius = (i % 2 == 0) ? sparkleSize : sparkleSize * 0.4;
                    vec3 offset = vec3(cos(angle) * radius, 0.0, sin(angle) * radius);
                    emitVertex(basePos + offset, centerUV, 2.0); // 2.0 標記為紫色閃光
                }
                EndPrimitive();
            }
        }
    }
}
