#version 330 core
layout (triangles) in;
layout (triangle_strip, max_vertices = 256) out;

in vec2 TexCoord[];
in vec3 RawPos[];

out vec2 gTexCoord;
out vec3 gRawPos;
out vec3 gNormal;
out float isPattern;
out float shouldColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform int activeFinger;
uniform int showPattern;
uniform float patternProgress;
uniform float time;
uniform int fingerPainted[6];

// 輸出單一頂點的輔助函數
void emitVertex(vec3 pos, vec2 uv, vec3 norm, float pattern) {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    gTexCoord = uv;
    gRawPos = pos;
    gNormal = norm;
    isPattern = pattern;
    shouldColor = 1.0;
    EmitVertex();
}

// 食指 (2) - 爆炸金字塔效果
void emitExplodingPyramid(vec3 v0, vec3 v1, vec3 v2, vec3 normal,
                          vec2 uv0, vec2 uv1, vec2 uv2, float seed, float progress) {
    float t = progress;
    // 爆炸強度：前半段增加，後半段減少
    float explosionIntensity = (t < 0.5) ? (t * 2.0) : (1.0 - (t - 0.5) * 2.0);
    float displacement = explosionIntensity * 1.0 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed * 1.5;

    vec3 centerBase = (v0 + v1 + v2) / 3.0;
    vec2 centerUV = (uv0 + uv1 + uv2) / 3.0;
    
    // 計算爆炸方向
    vec3 tangent = normalize(v1 - v0);
    vec3 bitangent = normalize(cross(normal, tangent));
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.6 + bitangent * (fract(seed * 7.13) - 0.5) * 0.6);
    vec3 offset = explosionDir * displacement;
    
    // 旋轉計算
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    // 位移
    vec3 nv0 = v0 + offset;
    vec3 nv1 = v1 + offset;
    vec3 nv2 = v2 + offset;
    vec3 nCenterBase = centerBase + offset;
    
    // 旋轉
    vec3 rot0 = nCenterBase + (nv0 - nCenterBase) * cosA + cross(normal, nv0 - nCenterBase) * sinA;
    vec3 rot1 = nCenterBase + (nv1 - nCenterBase) * cosA + cross(normal, nv1 - nCenterBase) * sinA;
    vec3 rot2 = nCenterBase + (nv2 - nCenterBase) * cosA + cross(normal, nv2 - nCenterBase) * sinA;
    
    // 金字塔頂點
    float pyramidHeight = mix(0.15, 0.3, fract(seed * 3.7));
    vec3 apex = nCenterBase + normal * pyramidHeight;
    
    // 輸出金字塔的四個面
    vec3 norm1 = normalize(cross(rot1 - rot0, apex - rot0));
    emitVertex(rot0, uv0, norm1, 2.0); emitVertex(rot1, uv1, norm1, 2.0); emitVertex(apex, centerUV, norm1, 2.0); EndPrimitive();
    
    vec3 norm2 = normalize(cross(rot2 - rot1, apex - rot1));
    emitVertex(rot1, uv1, norm2, 2.0); emitVertex(rot2, uv2, norm2, 2.0); emitVertex(apex, centerUV, norm2, 2.0); EndPrimitive();
    
    vec3 norm3 = normalize(cross(rot0 - rot2, apex - rot2));
    emitVertex(rot2, uv2, norm3, 2.0); emitVertex(rot0, uv0, norm3, 2.0); emitVertex(apex, centerUV, norm3, 2.0); EndPrimitive();
    
    vec3 bottomNorm = -normal;
    emitVertex(rot0, uv0, bottomNorm, 2.0); emitVertex(rot2, uv2, bottomNorm, 2.0); emitVertex(rot1, uv1, bottomNorm, 2.0); EndPrimitive();
}

// 大拇指 (1) - 生成立體鑽石
void emitDiamond(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                 float baseRadius, float height, vec2 uv) {
    int segments = 12;
    vec3 apex = center + normal * height;
    
    // 生成底部圓形的頂點
    vec3 basePoints[13];
    for (int i = 0; i <= segments; i++) {
        float angle = float(i) * 6.28318 / float(segments);
        float x = cos(angle) * baseRadius;
        float y = sin(angle) * baseRadius;
        basePoints[i] = center + tangent * x + bitangent * y;
    }
    
    // 輸出側面三角形
    for (int i = 0; i < segments; i++) {
        vec3 faceNorm = normalize(cross(basePoints[i] - apex, basePoints[i + 1] - apex));
        emitVertex(apex, uv, faceNorm, 1.0); emitVertex(basePoints[i], uv, faceNorm, 1.0); emitVertex(basePoints[i + 1], uv, faceNorm, 1.0); EndPrimitive();
    }
    
    // 輸出底面三角形
    vec3 bottomNorm = -normal;
    for (int i = 0; i < segments; i++) {
        emitVertex(center, uv, bottomNorm, 1.0); emitVertex(basePoints[i], uv, bottomNorm, 1.0); emitVertex(basePoints[i + 1], uv, bottomNorm, 1.0); EndPrimitive();
    }
}

// 中指 (3) - 星星
void emitRotatingStar(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                      float size, vec2 uv, float seed, bool isFinished) {
    // 完成後慢速旋轉，生長中快速旋轉
    float speedMultiplier = isFinished ? 0.5 : 2.0;
    float rotationSpeed = time * speedMultiplier + seed * 6.28318;
    float currentSize = isFinished ? size : size * min(patternProgress * 1.5, 1.0);
    
    // 生成 10 個星星頂點（交替長短形成星形）
    int numPoints = 10;
    vec3 starPoints[10];
    for (int i = 0; i < numPoints; i++) {
        float angle = float(i) * 6.28318 / float(numPoints) + rotationSpeed;
        float radius = (i % 2 == 0) ? currentSize : currentSize * 0.4;
        float x = cos(angle) * radius;
        float y = sin(angle) * radius;
        starPoints[i] = center + tangent * x + bitangent * y + normal * 0.01;
    }
    
    // 輸出星星三角形
    for (int i = 0; i < numPoints; i++) {
        int next = (i + 1) % numPoints;
        emitVertex(center + normal * 0.015, uv, normal, 3.0);
        emitVertex(starPoints[i], uv, normal, 3.0);
        emitVertex(starPoints[next], uv, normal, 3.0);
        EndPrimitive();
    }
}

// 根據 UV 座標判斷手指索引
// 返回值：0=手掌, 1=大拇指, 2=食指, 3=中指, 4=無名指, 5=小拇指
int getFingerIndex(vec2 uv) {
    if (uv.y < 0.1) {  // 指甲區域
        if (uv.x < 0.5) {  // 左手
            if (uv.x < 0.1) return 5;      // 小拇指
            else if (uv.x < 0.2) return 4; // 無名指
            else if (uv.x < 0.3) return 3; // 中指
            else if (uv.x < 0.4) return 2; // 食指
            else return 1;                  // 大拇指
        } else {  // 右手
            if (uv.x < 0.6) return 1;      // 大拇指
            else if (uv.x < 0.7) return 2; // 食指
            else if (uv.x < 0.8) return 3; // 中指
            else if (uv.x < 0.9) return 4; // 無名指
            else return 5;                  // 小拇指
        }
    }
    return 0;  // 手掌
}

void main() {
    vec2 centerUV = (TexCoord[0] + TexCoord[1] + TexCoord[2]) / 3.0;
    vec3 centerRaw = (RawPos[0] + RawPos[1] + RawPos[2]) / 3.0;
    
    // 1. 輸出原始三角形（手部模型本身）
    vec3 triNormal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
    for (int i = 0; i < 3; i++) {
        emitVertex(RawPos[i], TexCoord[i], triNormal, 0.0);
    }
    EndPrimitive();

    // 判斷當前三角形屬於哪個手指
    int fingerIdx = getFingerIndex(centerUV);
    bool isNailArea = (centerUV.y < 0.08 && centerUV.y > 0.01);  // 指甲區域
    bool isGrowing = (fingerIdx == activeFinger && patternProgress > 0.01);  // 正在生長
    bool isFinished = (fingerIdx > 0 && fingerIdx < 6 && fingerPainted[fingerIdx] == 1);  // 已完成

    // 大拇指(1) 紫色鑽石裝飾
    if (showPattern > 0 && isNailArea && fingerIdx == 1 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {  // 只在向上的面生成
            float hash = fract(sin(dot(centerUV, vec2(17.9128, 83.2331))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress;
            if (hash < currentProgress * 0.5) {  // 根據進度控制密度
                vec3 tangent = normalize(RawPos[1] - RawPos[0]); 
                if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent)); 
                if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                float normalizedHash = fract(hash * 7.1234);
                // 鑽石大小隨進度增長
                float baseRadius = mix(0.04, 0.09, normalizedHash) * currentProgress;
                float height = mix(0.1, 0.25, normalizedHash) * currentProgress;
                emitDiamond(centerRaw + normal * 0.01, normal, tangent, bitangent, baseRadius, height, centerUV);
            }
         }
    }
    
    // 食指(2) 白色爆炸金字塔裝飾
    if (showPattern > 0 && isNailArea && fingerIdx == 2 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {  // 只在向上的面生成
            float hash = fract(sin(dot(centerUV, vec2(23.4567, 65.7891))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress;
            
            if (hash < currentProgress * 0.6) {  // 根據進度控制密度
                emitExplodingPyramid(RawPos[0], RawPos[1], RawPos[2], normal, TexCoord[0], TexCoord[1], TexCoord[2], hash, currentProgress);
            }
         }
    }

    // 中指(3) 星星
    if (showPattern > 0 && isNailArea && fingerIdx == 3 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {  // 只在向上的面生成
            float hash = fract(sin(dot(centerUV, vec2(31.4159, 27.1828))) * 43758.5453);
            if (hash < 0.5) {  // 50% 的三角形生成星星
                vec3 tangent = normalize(RawPos[1] - RawPos[0]); 
                if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent)); 
                if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                float starSize = mix(0.06, 0.12, fract(hash * 3.7));
                emitRotatingStar(centerRaw, normal, tangent, bitangent, starSize, centerUV, hash, isFinished);
            }
         }
    }
}