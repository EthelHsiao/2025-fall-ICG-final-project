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

void emitVertex(vec3 pos, vec2 uv, vec3 norm, float pattern) {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    gTexCoord = uv;
    gRawPos = pos;
    gNormal = norm;
    isPattern = pattern;
    shouldColor = 1.0;
    EmitVertex();
}

// [修改 1] 增加 progress 參數
void emitExplodingPyramid(vec3 v0, vec3 v1, vec3 v2, vec3 normal,
                          vec2 uv0, vec2 uv1, vec2 uv2, float seed, float progress) {
    float t = progress; // 使用傳入的進度，而非全域 patternProgress
    float explosionIntensity = (t < 0.5) ? (t * 2.0) : (1.0 - (t - 0.5) * 2.0);
    float displacement = explosionIntensity * 1.0 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed * 1.5;

    vec3 centerBase = (v0 + v1 + v2) / 3.0;
    vec2 centerUV = (uv0 + uv1 + uv2) / 3.0;
    
    vec3 tangent = normalize(v1 - v0);
    vec3 bitangent = normalize(cross(normal, tangent));
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.6 + bitangent * (fract(seed * 7.13) - 0.5) * 0.6);
    vec3 offset = explosionDir * displacement;
    
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    vec3 nv0 = v0 + offset;
    vec3 nv1 = v1 + offset;
    vec3 nv2 = v2 + offset;
    vec3 nCenterBase = centerBase + offset;
    
    vec3 rot0 = nCenterBase + (nv0 - nCenterBase) * cosA + cross(normal, nv0 - nCenterBase) * sinA;
    vec3 rot1 = nCenterBase + (nv1 - nCenterBase) * cosA + cross(normal, nv1 - nCenterBase) * sinA;
    vec3 rot2 = nCenterBase + (nv2 - nCenterBase) * cosA + cross(normal, nv2 - nCenterBase) * sinA;
    
    float pyramidHeight = mix(0.15, 0.3, fract(seed * 3.7));
    vec3 apex = nCenterBase + normal * pyramidHeight;
    
    vec3 norm1 = normalize(cross(rot1 - rot0, apex - rot0));
    emitVertex(rot0, uv0, norm1, 2.0); emitVertex(rot1, uv1, norm1, 2.0); emitVertex(apex, centerUV, norm1, 2.0); EndPrimitive();
    
    vec3 norm2 = normalize(cross(rot2 - rot1, apex - rot1));
    emitVertex(rot1, uv1, norm2, 2.0); emitVertex(rot2, uv2, norm2, 2.0); emitVertex(apex, centerUV, norm2, 2.0); EndPrimitive();
    
    vec3 norm3 = normalize(cross(rot0 - rot2, apex - rot2));
    emitVertex(rot2, uv2, norm3, 2.0); emitVertex(rot0, uv0, norm3, 2.0); emitVertex(apex, centerUV, norm3, 2.0); EndPrimitive();
    
    vec3 bottomNorm = -normal;
    emitVertex(rot0, uv0, bottomNorm, 2.0); emitVertex(rot2, uv2, bottomNorm, 2.0); emitVertex(rot1, uv1, bottomNorm, 2.0); EndPrimitive();
}

// [修改 2] 增加 progress 參數
void emitExplodingCube(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                       float size, vec2 uv, float seed, float progress) {
    float explosionIntensity = progress; // 使用傳入的進度
    float displacement = explosionIntensity * 1.2 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed * 2.0;
    
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.8 + bitangent * (fract(seed * 7.13) - 0.5) * 0.8);
    vec3 offset = explosionDir * displacement;
    
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    vec3 newCenter = center + offset;
    float halfSize = size * 0.5;
    
    vec3 v[8];
    v[0] = vec3(-halfSize, -halfSize, -halfSize); v[1] = vec3( halfSize, -halfSize, -halfSize);
    v[2] = vec3( halfSize,  halfSize, -halfSize); v[3] = vec3(-halfSize,  halfSize, -halfSize);
    v[4] = vec3(-halfSize, -halfSize,  halfSize); v[5] = vec3( halfSize, -halfSize,  halfSize);
    v[6] = vec3( halfSize,  halfSize,  halfSize); v[7] = vec3(-halfSize,  halfSize,  halfSize);
    
    for (int i = 0; i < 8; i++) {
        float rx = v[i].x * cosA - v[i].z * sinA;
        float rz = v[i].x * sinA + v[i].z * cosA;
        v[i] = newCenter + tangent * rx + normal * v[i].y + bitangent * rz;
    }
    
    vec3 norm;
    // 前
    norm = normalize(cross(v[1] - v[0], v[3] - v[0]));
    emitVertex(v[0], uv, norm, 2.0); emitVertex(v[1], uv, norm, 2.0); emitVertex(v[3], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[1], uv, norm, 2.0); emitVertex(v[2], uv, norm, 2.0); emitVertex(v[3], uv, norm, 2.0); EndPrimitive();
    // 後
    norm = normalize(cross(v[5] - v[4], v[7] - v[4]));
    emitVertex(v[5], uv, norm, 2.0); emitVertex(v[4], uv, norm, 2.0); emitVertex(v[6], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[4], uv, norm, 2.0); emitVertex(v[7], uv, norm, 2.0); emitVertex(v[6], uv, norm, 2.0); EndPrimitive();
    // 上
    norm = normalize(cross(v[6] - v[2], v[3] - v[2]));
    emitVertex(v[3], uv, norm, 2.0); emitVertex(v[2], uv, norm, 2.0); emitVertex(v[7], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[2], uv, norm, 2.0); emitVertex(v[6], uv, norm, 2.0); emitVertex(v[7], uv, norm, 2.0); EndPrimitive();
    // 下
    norm = normalize(cross(v[4] - v[0], v[1] - v[0]));
    emitVertex(v[0], uv, norm, 2.0); emitVertex(v[4], uv, norm, 2.0); emitVertex(v[1], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[4], uv, norm, 2.0); emitVertex(v[5], uv, norm, 2.0); emitVertex(v[1], uv, norm, 2.0); EndPrimitive();
    // 左
    norm = normalize(cross(v[4] - v[0], v[3] - v[0]));
    emitVertex(v[0], uv, norm, 2.0); emitVertex(v[3], uv, norm, 2.0); emitVertex(v[4], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[3], uv, norm, 2.0); emitVertex(v[7], uv, norm, 2.0); emitVertex(v[4], uv, norm, 2.0); EndPrimitive();
    // 右
    norm = normalize(cross(v[2] - v[1], v[5] - v[1]));
    emitVertex(v[1], uv, norm, 2.0); emitVertex(v[5], uv, norm, 2.0); emitVertex(v[2], uv, norm, 2.0); EndPrimitive();
    emitVertex(v[5], uv, norm, 2.0); emitVertex(v[6], uv, norm, 2.0); emitVertex(v[2], uv, norm, 2.0); EndPrimitive();
}

// [修改 3] 增加 progress 參數
void emitExplodingDiamond(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                          float baseRadius, float height, vec2 uv, float seed, float progress) {
    int segments = 12;
    float explosionIntensity = progress; // 使用傳入的進度
    float displacement = explosionIntensity * 0.8 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed;
    
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.5 + bitangent * (fract(seed * 7.13) - 0.5) * 0.5);
    vec3 offset = explosionDir * displacement;
    
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    vec3 newCenter = center + offset;
    vec3 apex = newCenter + normal * height;
    
    vec3 basePoints[13];
    for (int i = 0; i <= segments; i++) {
        float angle = float(i) * 6.28318 / float(segments);
        float x = cos(angle) * baseRadius;
        float y = sin(angle) * baseRadius;
        float rx = x * cosA - y * sinA;
        float ry = x * sinA + y * cosA;
        basePoints[i] = newCenter + tangent * rx + bitangent * ry;
    }
    
    for (int i = 0; i < segments; i++) {
        vec3 faceNorm = normalize(cross(basePoints[i] - apex, basePoints[i + 1] - apex));
        emitVertex(apex, uv, faceNorm, 1.0); emitVertex(basePoints[i], uv, faceNorm, 1.0); emitVertex(basePoints[i + 1], uv, faceNorm, 1.0); EndPrimitive();
    }
    vec3 bottomNorm = -normal;
    for (int i = 0; i < segments; i++) {
        emitVertex(newCenter, uv, bottomNorm, 1.0); emitVertex(basePoints[i], uv, bottomNorm, 1.0); emitVertex(basePoints[i + 1], uv, bottomNorm, 1.0); EndPrimitive();
    }
}

// [修改 4] 增加 progress 參數
void emitFireworks(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                   vec2 uv, float seed, float progress) {
    int numSparks = 12;
    float t = progress; // 使用傳入的進度
    float launchHeight = t * 0.8;
    float spreadRadius = t * 0.4;
    
    for (int i = 0; i < numSparks; i++) {
        float sparkSeed = fract(seed * 7.123 + float(i) * 0.618);
        float angle = sparkSeed * 6.28318;
        float heightOffset = launchHeight + sin(t * 6.28318 + sparkSeed * 10.0) * 0.1;
        
        vec3 dir = normalize(normal * 0.7 + tangent * cos(angle) * 0.3 + bitangent * sin(angle) * 0.3);
        vec3 sparkPos = center + dir * heightOffset + 
                       tangent * cos(angle) * spreadRadius * sparkSeed + 
                       bitangent * sin(angle) * spreadRadius * sparkSeed;
        vec3 sparkNorm = normalize(sparkPos - center);
        emitVertex(sparkPos, uv, sparkNorm, 3.0);
        EndPrimitive();
    }
}

// 生成立體鑽石 (無爆炸效果，用於大拇指生長)
void emitDiamond(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                 float baseRadius, float height, vec2 uv) {
    int segments = 12;
    vec3 apex = center + normal * height;
    vec3 basePoints[13];
    for (int i = 0; i <= segments; i++) {
        float angle = float(i) * 6.28318 / float(segments);
        float x = cos(angle) * baseRadius;
        float y = sin(angle) * baseRadius;
        basePoints[i] = center + tangent * x + bitangent * y;
    }
    for (int i = 0; i < segments; i++) {
        vec3 faceNorm = normalize(cross(basePoints[i] - apex, basePoints[i + 1] - apex));
        emitVertex(apex, uv, faceNorm, 1.0); emitVertex(basePoints[i], uv, faceNorm, 1.0); emitVertex(basePoints[i + 1], uv, faceNorm, 1.0); EndPrimitive();
    }
    vec3 bottomNorm = -normal;
    for (int i = 0; i < segments; i++) {
        emitVertex(center, uv, bottomNorm, 1.0); emitVertex(basePoints[i], uv, bottomNorm, 1.0); emitVertex(basePoints[i + 1], uv, bottomNorm, 1.0); EndPrimitive();
    }
}

// 生成旋轉星星
void emitRotatingStar(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                      float size, vec2 uv, float seed, bool isFinished) {
    float speedMultiplier = isFinished ? 0.5 : 2.0;
    float rotationSpeed = time * speedMultiplier + seed * 6.28318;
    float currentSize = isFinished ? size : size * min(patternProgress * 1.5, 1.0);
    
    int numPoints = 10;
    vec3 starPoints[10];
    for (int i = 0; i < numPoints; i++) {
        float angle = float(i) * 6.28318 / float(numPoints) + rotationSpeed;
        float radius = (i % 2 == 0) ? currentSize : currentSize * 0.4;
        float x = cos(angle) * radius;
        float y = sin(angle) * radius;
        starPoints[i] = center + tangent * x + bitangent * y + normal * 0.01;
    }
    for (int i = 0; i < numPoints; i++) {
        int next = (i + 1) % numPoints;
        emitVertex(center + normal * 0.015, uv, normal, 3.0);
        emitVertex(starPoints[i], uv, normal, 3.0);
        emitVertex(starPoints[next], uv, normal, 3.0);
        EndPrimitive();
    }
}

// [新增] 生成立體蝴蝶結 (用於小拇指)
void emitBow(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
             float size, vec2 uv, float seed, bool isFinished) {
    
    // 生長動畫：如果未完成，大小隨進度變化；如果完成，固定為最大
    float currentSize = isFinished ? size : size * smoothstep(0.0, 1.0, patternProgress);
    
    float knotSize = currentSize * 0.25; 
    float wingWidth = currentSize * 1.0; 
    float wingHeight = currentSize * 0.7; 
    float lift = 0.02; 
    vec3 centerPos = center + normal * lift;
    vec3 knotApex = centerPos + normal * knotSize * 0.8;
    
    // 中心結
    vec3 k1 = centerPos - tangent * knotSize - bitangent * knotSize;
    vec3 k2 = centerPos + tangent * knotSize - bitangent * knotSize;
    vec3 k3 = centerPos + tangent * knotSize + bitangent * knotSize;
    vec3 k4 = centerPos - tangent * knotSize + bitangent * knotSize;
    
    vec3 nK1 = normalize(cross(k2 - k1, knotApex - k1));
    emitVertex(k1, uv, nK1, 4.0); emitVertex(k2, uv, nK1, 4.0); emitVertex(knotApex, uv, nK1, 4.0); EndPrimitive();
    vec3 nK2 = normalize(cross(k3 - k2, knotApex - k2));
    emitVertex(k2, uv, nK2, 4.0); emitVertex(k3, uv, nK2, 4.0); emitVertex(knotApex, uv, nK2, 4.0); EndPrimitive();
    vec3 nK3 = normalize(cross(k4 - k3, knotApex - k3));
    emitVertex(k3, uv, nK3, 4.0); emitVertex(k4, uv, nK3, 4.0); emitVertex(knotApex, uv, nK3, 4.0); EndPrimitive();
    vec3 nK4 = normalize(cross(k1 - k4, knotApex - k4));
    emitVertex(k4, uv, nK4, 4.0); emitVertex(k1, uv, nK4, 4.0); emitVertex(knotApex, uv, nK4, 4.0); EndPrimitive();

    // 左翅膀
    vec3 lCenter = centerPos - tangent * (knotSize + wingWidth * 0.5);
    vec3 lTop = lCenter + bitangent * wingHeight;
    vec3 lBottom = lCenter - bitangent * wingHeight;
    vec3 lAttach = centerPos - tangent * knotSize * 0.8;
    vec3 lTipNormal = normalize(normal - tangent * 0.5); 
    emitVertex(lAttach, uv, normal, 4.0); emitVertex(lBottom, uv, lTipNormal, 4.0); emitVertex(lTop, uv, lTipNormal, 4.0); EndPrimitive();

    // 右翅膀
    vec3 rCenter = centerPos + tangent * (knotSize + wingWidth * 0.5); 
    vec3 rTop = rCenter + bitangent * wingHeight;
    vec3 rBottom = rCenter - bitangent * wingHeight;
    vec3 rAttach = centerPos + tangent * knotSize * 0.8;
    vec3 rTipNormal = normalize(normal + tangent * 0.5);
    emitVertex(rAttach, uv, normal, 4.0); emitVertex(rTop, uv, rTipNormal, 4.0); emitVertex(rBottom, uv, rTipNormal, 4.0); EndPrimitive();
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
    vec3 triNormal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
    for (int i = 0; i < 3; i++) {
        emitVertex(RawPos[i], TexCoord[i], triNormal, 0.0);
    }
    EndPrimitive();

    int fingerIdx = getFingerIndex(centerUV);
    bool isNailArea = (centerUV.y < 0.08 && centerUV.y > 0.01);
    bool isGrowing = (fingerIdx == activeFinger && patternProgress > 0.01);
    bool isFinished = (fingerIdx > 0 && fingerIdx < 6 && fingerPainted[fingerIdx] == 1);

    // [大拇指 1] 鑽石
    if (showPattern > 0 && isNailArea && fingerIdx == 1 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(17.9128, 83.2331))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress;
            if (hash < currentProgress * 0.5) {
                vec3 tangent = normalize(RawPos[1] - RawPos[0]); if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent)); if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                float normalizedHash = fract(hash * 7.1234);
                float baseRadius = mix(0.04, 0.09, normalizedHash) * currentProgress;
                float height = mix(0.1, 0.25, normalizedHash) * currentProgress;
                emitDiamond(centerRaw + normal * 0.01, normal, tangent, bitangent, baseRadius, height, centerUV);
            }
         }
    }
    
    // [食指 2] 金字塔爆炸 - 修改呼叫，傳入 currentProgress
    if (showPattern > 0 && isNailArea && fingerIdx == 2 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(23.4567, 65.7891))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress; // 確保已完成的是 1.0
            
            if (hash < currentProgress * 0.6) {
                // 傳入 currentProgress
                emitExplodingPyramid(RawPos[0], RawPos[1], RawPos[2], normal, TexCoord[0], TexCoord[1], TexCoord[2], hash, currentProgress);
            }
         }
    }

    // [中指 3] 旋轉星星
    if (showPattern > 0 && isNailArea && fingerIdx == 3 && (isGrowing || isFinished)) {
         vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
         if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(31.4159, 27.1828))) * 43758.5453);
            if (hash < 0.5) {
                vec3 tangent = normalize(RawPos[1] - RawPos[0]); if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent)); if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                float starSize = mix(0.06, 0.12, fract(hash * 3.7));
                emitRotatingStar(centerRaw, normal, tangent, bitangent, starSize, centerUV, hash, isFinished);
            }
         }
    }

    
}