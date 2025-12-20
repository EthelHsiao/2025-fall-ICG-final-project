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
uniform int fingerPainted[6]; // ★ 新增:接收已完成手指的陣列

void emitVertex(vec3 pos, vec2 uv, vec3 norm, float pattern) {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    gTexCoord = uv;
    gRawPos = pos;
    gNormal = norm;
    isPattern = pattern;
    shouldColor = 1.0;
    EmitVertex();
}

// 生成爆炸金字塔：從三角形基底向上延伸出頂點
void emitExplodingPyramid(vec3 v0, vec3 v1, vec3 v2, vec3 normal,
                          vec2 uv0, vec2 uv1, vec2 uv2, float seed) {
    // 爆炸參數
    float t = patternProgress;
    float explosionIntensity = (t < 0.5) ? (t * 2.0) : (1.0 - (t - 0.5) * 2.0); // 0~1~0
    float displacement = explosionIntensity * 1.0 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed * 1.5;
    
    // 計算三角形中心
    vec3 centerBase = (v0 + v1 + v2) / 3.0;
    vec2 centerUV = (uv0 + uv1 + uv2) / 3.0;
    
    // 計算爆炸方向
    vec3 tangent = normalize(v1 - v0);
    vec3 bitangent = normalize(cross(normal, tangent));
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.6 + bitangent * (fract(seed * 7.13) - 0.5) * 0.6);
    vec3 offset = explosionDir * displacement;
    
    // 旋轉矩陣（繞法線旋轉）
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    // 應用爆炸位移到所有頂點
    vec3 nv0 = v0 + offset;
    vec3 nv1 = v1 + offset;
    vec3 nv2 = v2 + offset;
    vec3 nCenterBase = centerBase + offset;
    
    // 應用旋轉（繞中心點）
    vec3 rot0 = nCenterBase + (nv0 - nCenterBase) * cosA + cross(normal, nv0 - nCenterBase) * sinA;
    vec3 rot1 = nCenterBase + (nv1 - nCenterBase) * cosA + cross(normal, nv1 - nCenterBase) * sinA;
    vec3 rot2 = nCenterBase + (nv2 - nCenterBase) * cosA + cross(normal, nv2 - nCenterBase) * sinA;
    
    // 計算金字塔頂點（沿法線延伸）
    float pyramidHeight = mix(0.15, 0.3, fract(seed * 3.7));
    vec3 apex = nCenterBase + normal * pyramidHeight;
    
    // 繪製3個側面
    // 面 1: v0 -> v1 -> apex
    vec3 norm1 = normalize(cross(rot1 - rot0, apex - rot0));
    emitVertex(rot0, uv0, norm1, 2.0);
    emitVertex(rot1, uv1, norm1, 2.0);
    emitVertex(apex, centerUV, norm1, 2.0);
    EndPrimitive();
    
    // 面 2: v1 -> v2 -> apex
    vec3 norm2 = normalize(cross(rot2 - rot1, apex - rot1));
    emitVertex(rot1, uv1, norm2, 2.0);
    emitVertex(rot2, uv2, norm2, 2.0);
    emitVertex(apex, centerUV, norm2, 2.0);
    EndPrimitive();
    
    // 面 3: v2 -> v0 -> apex
    vec3 norm3 = normalize(cross(rot0 - rot2, apex - rot2));
    emitVertex(rot2, uv2, norm3, 2.0);
    emitVertex(rot0, uv0, norm3, 2.0);
    emitVertex(apex, centerUV, norm3, 2.0);
    EndPrimitive();
    
    // 底面
    vec3 bottomNorm = -normal;
    emitVertex(rot0, uv0, bottomNorm, 2.0);
    emitVertex(rot2, uv2, bottomNorm, 2.0);
    emitVertex(rot1, uv1, bottomNorm, 2.0);
    EndPrimitive();
}

// 生成爆炸立方碎片：沿法線方向向外飛散並旋轉
void emitExplodingCube(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                       float size, vec2 uv, float seed) {
    // 爆炸參數
    float explosionIntensity = patternProgress;
    float displacement = explosionIntensity * 1.2 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed * 2.0;
    
    // 計算爆炸方向
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.8 + bitangent * (fract(seed * 7.13) - 0.5) * 0.8);
    vec3 offset = explosionDir * displacement;
    
    // 旋轉矩陣（繞 Y 軸）
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    vec3 newCenter = center + offset;
    float halfSize = size * 0.5;
    
    // 定義立方體 8 個頂點（相對於中心）
    vec3 v[8];
    v[0] = vec3(-halfSize, -halfSize, -halfSize);
    v[1] = vec3( halfSize, -halfSize, -halfSize);
    v[2] = vec3( halfSize,  halfSize, -halfSize);
    v[3] = vec3(-halfSize,  halfSize, -halfSize);
    v[4] = vec3(-halfSize, -halfSize,  halfSize);
    v[5] = vec3( halfSize, -halfSize,  halfSize);
    v[6] = vec3( halfSize,  halfSize,  halfSize);
    v[7] = vec3(-halfSize,  halfSize,  halfSize);
    
    // 應用旋轉並轉換到世界空間
    for (int i = 0; i < 8; i++) {
        // 旋轉 XZ 平面
        float rx = v[i].x * cosA - v[i].z * sinA;
        float rz = v[i].x * sinA + v[i].z * cosA;
        v[i] = newCenter + tangent * rx + normal * v[i].y + bitangent * rz;
    }
    
    // 繪製 6 個面（每面兩個三角形）
    // 前面
    vec3 norm = normalize(cross(v[1] - v[0], v[3] - v[0]));
    emitVertex(v[0], uv, norm, 2.0);  // 2.0 = 食指標記
    emitVertex(v[1], uv, norm, 2.0);
    emitVertex(v[3], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[1], uv, norm, 2.0);
    emitVertex(v[2], uv, norm, 2.0);
    emitVertex(v[3], uv, norm, 2.0);
    EndPrimitive();
    
    // 後面
    norm = normalize(cross(v[5] - v[4], v[7] - v[4]));
    emitVertex(v[5], uv, norm, 2.0);
    emitVertex(v[4], uv, norm, 2.0);
    emitVertex(v[6], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[4], uv, norm, 2.0);
    emitVertex(v[7], uv, norm, 2.0);
    emitVertex(v[6], uv, norm, 2.0);
    EndPrimitive();
    
    // 上面
    norm = normalize(cross(v[6] - v[2], v[3] - v[2]));
    emitVertex(v[3], uv, norm, 2.0);
    emitVertex(v[2], uv, norm, 2.0);
    emitVertex(v[7], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[2], uv, norm, 2.0);
    emitVertex(v[6], uv, norm, 2.0);
    emitVertex(v[7], uv, norm, 2.0);
    EndPrimitive();
    
    // 下面
    norm = normalize(cross(v[4] - v[0], v[1] - v[0]));
    emitVertex(v[0], uv, norm, 2.0);
    emitVertex(v[4], uv, norm, 2.0);
    emitVertex(v[1], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[4], uv, norm, 2.0);
    emitVertex(v[5], uv, norm, 2.0);
    emitVertex(v[1], uv, norm, 2.0);
    EndPrimitive();
    
    // 左面
    norm = normalize(cross(v[4] - v[0], v[3] - v[0]));
    emitVertex(v[0], uv, norm, 2.0);
    emitVertex(v[3], uv, norm, 2.0);
    emitVertex(v[4], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[3], uv, norm, 2.0);
    emitVertex(v[7], uv, norm, 2.0);
    emitVertex(v[4], uv, norm, 2.0);
    EndPrimitive();
    
    // 右面
    norm = normalize(cross(v[2] - v[1], v[5] - v[1]));
    emitVertex(v[1], uv, norm, 2.0);
    emitVertex(v[5], uv, norm, 2.0);
    emitVertex(v[2], uv, norm, 2.0);
    EndPrimitive();
    emitVertex(v[5], uv, norm, 2.0);
    emitVertex(v[6], uv, norm, 2.0);
    emitVertex(v[2], uv, norm, 2.0);
    EndPrimitive();
}

// 生成爆炸鑽石：沿法線方向向外飛散並旋轉
void emitExplodingDiamond(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                          float baseRadius, float height, vec2 uv, float seed) {
    int segments = 12;
    
    // 爆炸參數
    float explosionIntensity = patternProgress;
    float displacement = explosionIntensity * 0.8 * seed;
    float rotationAngle = explosionIntensity * 6.28318 * seed;
    
    // 計算爆炸方向（沿法線 + 隨機偏移）
    vec3 explosionDir = normalize(normal + tangent * (seed - 0.5) * 0.5 + bitangent * (fract(seed * 7.13) - 0.5) * 0.5);
    vec3 offset = explosionDir * displacement;
    
    // 旋轉矩陣（簡化版：繞 Y 軸旋轉）
    float cosA = cos(rotationAngle);
    float sinA = sin(rotationAngle);
    
    vec3 newCenter = center + offset;
    vec3 apex = newCenter + normal * height;
    
    // 計算底部圓周上的點
    vec3 basePoints[13];
    for (int i = 0; i <= segments; i++) {
        float angle = float(i) * 6.28318 / float(segments);
        float x = cos(angle) * baseRadius;
        float y = sin(angle) * baseRadius;
        // 應用旋轉
        float rx = x * cosA - y * sinA;
        float ry = x * sinA + y * cosA;
        basePoints[i] = newCenter + tangent * rx + bitangent * ry;
    }
    
    // 繪製側面
    for (int i = 0; i < segments; i++) {
        vec3 faceNorm = normalize(cross(
            basePoints[i] - apex,
            basePoints[i + 1] - apex
        ));
        emitVertex(apex, uv, faceNorm, 1.0);
        emitVertex(basePoints[i], uv, faceNorm, 1.0);
        emitVertex(basePoints[i + 1], uv, faceNorm, 1.0);
        EndPrimitive();
    }
    
    // 繪製底面
    vec3 bottomNorm = -normal;
    for (int i = 0; i < segments; i++) {
        emitVertex(newCenter, uv, bottomNorm, 1.0);
        emitVertex(basePoints[i], uv, bottomNorm, 1.0);
        emitVertex(basePoints[i + 1], uv, bottomNorm, 1.0);
        EndPrimitive();
    }
}

// 生成煙火效果：從中心向上噴發多個火花粒子
void emitFireworks(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent,
                   vec2 uv, float seed) {
    int numSparks = 12;
    float t = patternProgress;
    float launchHeight = t * 0.8; // 向上噴發高度
    float spreadRadius = t * 0.4; // 擴散半徑
    
    for (int i = 0; i < numSparks; i++) {
        float sparkSeed = fract(seed * 7.123 + float(i) * 0.618);
        float angle = sparkSeed * 6.28318;
        float heightOffset = launchHeight + sin(t * 6.28318 + sparkSeed * 10.0) * 0.1; // 波動效果
        
        // 隨機方向，主要向上
        vec3 dir = normalize(normal * 0.7 + tangent * cos(angle) * 0.3 + bitangent * sin(angle) * 0.3);
        vec3 sparkPos = center + dir * heightOffset + 
                       tangent * cos(angle) * spreadRadius * sparkSeed + 
                       bitangent * sin(angle) * spreadRadius * sparkSeed;
        
        // 每個火花是一個小點（單個頂點）
        vec3 sparkNorm = normalize(sparkPos - center);
        emitVertex(sparkPos, uv, sparkNorm, 3.0); // 3.0 = 煙火標記
        EndPrimitive();
    }
}

// 生成立體鑽石/稜錐：底部為圓形，頂點為尖端
// 使用 triangle strip 連接底部圓周與頂點形成錐面
void emitDiamond(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                 float baseRadius, float height, vec2 uv) {
    int segments = 12;
    vec3 apex = center + normal * height;
    
    // 計算底部圓周上的點
    vec3 basePoints[13];
    for (int i = 0; i <= segments; i++) {
        float angle = float(i) * 6.28318 / float(segments);
        float x = cos(angle) * baseRadius;
        float y = sin(angle) * baseRadius;
        basePoints[i] = center + tangent * x + bitangent * y;
    }
    
    // 繪製側面：每個三角形從頂點連到底部相鄰兩點
    for (int i = 0; i < segments; i++) {
        // 計算此三角形面的法線
        vec3 faceNorm = normalize(cross(
            basePoints[i] - apex,
            basePoints[i + 1] - apex
        ));
        emitVertex(apex, uv, faceNorm, 1.0);
        emitVertex(basePoints[i], uv, faceNorm, 1.0);
        emitVertex(basePoints[i + 1], uv, faceNorm, 1.0);
        EndPrimitive();
    }
    
    // 繪製底面（可選，增加立體感）
    vec3 bottomNorm = -normal;
    for (int i = 0; i < segments; i++) {
        emitVertex(center, uv, bottomNorm, 1.0);
        emitVertex(basePoints[i], uv, bottomNorm, 1.0);
        emitVertex(basePoints[i + 1], uv, bottomNorm, 1.0);
        EndPrimitive();
    }
}

// 優化 emitRotatingStar 函式，讓它支援持續顯示
void emitRotatingStar(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                      float size, vec2 uv, float seed, bool isFinished) {
    // 如果已完成，讓它轉慢一點，展現優雅感；生長時轉快一點
    float speedMultiplier = isFinished ? 0.5 : 2.0;
    float rotationSpeed = time * speedMultiplier + seed * 6.28318;
    // 如果已完成，尺寸固定為最大；否則隨進度長大
    float currentSize = isFinished ? size : size * min(patternProgress * 1.5, 1.0);
    int numPoints = 10;
    vec3 starPoints[10];
    for (int i = 0; i < numPoints; i++) {
        float angle = float(i) * 6.28318 / float(numPoints) + rotationSpeed;
        float radius = (i % 2 == 0) ? currentSize : currentSize * 0.4;
        float x = cos(angle) * radius;
        float y = sin(angle) * radius;
        // 稍微浮起 (normal * 0.01) 避免重疊
        starPoints[i] = center + tangent * x + bitangent * y + normal * 0.01;
    }
    // 繪製
    for (int i = 0; i < numPoints; i++) {
        int next = (i + 1) % numPoints;
        // 3.0 代表中指星星 ID
        emitVertex(center + normal * 0.015, uv, normal, 3.0); 
        emitVertex(starPoints[i], uv, normal, 3.0);
        emitVertex(starPoints[next], uv, normal, 3.0);
        EndPrimitive();
    }
}

// 生成可愛蝴蝶結：兩個側翼 + 中央結點
void emitBowTie(vec3 center, vec3 normal, vec3 tangent, vec3 bitangent, 
                float size, vec2 uv, float seed, bool isFinished) {
    // 如果已完成，輕微擺動；生長時從小變大
    float swaySpeed = isFinished ? 0.3 : 1.0;
    float sway = sin(time * swaySpeed + seed * 3.14159) * 0.05;
    float currentSize = isFinished ? size : size * min(patternProgress * 1.2, 1.0);
    
    // 蝴蝶結參數
    float wingWidth = currentSize * 0.8;
    float wingHeight = currentSize * 0.6;
    float knotWidth = currentSize * 0.3;
    float knotHeight = currentSize * 0.4;
    
    // 添加輕微擺動
    vec3 swayTangent = tangent * cos(sway) + bitangent * sin(sway);
    vec3 swayBitangent = normalize(cross(normal, swayTangent));
    
    // 左翼
    vec3 leftWingPoints[4];
    leftWingPoints[0] = center + swayTangent * (-wingWidth * 0.3) + swayBitangent * (-wingHeight * 0.5) + normal * 0.02;
    leftWingPoints[1] = center + swayTangent * (-wingWidth) + swayBitangent * (-wingHeight * 0.2) + normal * 0.03;
    leftWingPoints[2] = center + swayTangent * (-wingWidth) + swayBitangent * (wingHeight * 0.2) + normal * 0.03;
    leftWingPoints[3] = center + swayTangent * (-wingWidth * 0.3) + swayBitangent * (wingHeight * 0.5) + normal * 0.02;
    
    // 右翼
    vec3 rightWingPoints[4];
    rightWingPoints[0] = center + swayTangent * (wingWidth * 0.3) + swayBitangent * (-wingHeight * 0.5) + normal * 0.02;
    rightWingPoints[1] = center + swayTangent * (wingWidth) + swayBitangent * (-wingHeight * 0.2) + normal * 0.03;
    rightWingPoints[2] = center + swayTangent * (wingWidth) + swayBitangent * (wingHeight * 0.2) + normal * 0.03;
    rightWingPoints[3] = center + swayTangent * (wingWidth * 0.3) + swayBitangent * (wingHeight * 0.5) + normal * 0.02;
    
    // 中央結點
    vec3 knotPoints[4];
    knotPoints[0] = center + swayTangent * (-knotWidth * 0.5) + swayBitangent * (-knotHeight * 0.5) + normal * 0.04;
    knotPoints[1] = center + swayTangent * (knotWidth * 0.5) + swayBitangent * (-knotHeight * 0.5) + normal * 0.04;
    knotPoints[2] = center + swayTangent * (knotWidth * 0.5) + swayBitangent * (knotHeight * 0.5) + normal * 0.04;
    knotPoints[3] = center + swayTangent * (-knotWidth * 0.5) + swayBitangent * (knotHeight * 0.5) + normal * 0.04;
    
    // 繪製左翼（兩個三角形）
    // 4.0 = 小指蝴蝶結 ID
    emitVertex(leftWingPoints[0], uv, normal, 4.0);
    emitVertex(leftWingPoints[1], uv, normal, 4.0);
    emitVertex(leftWingPoints[3], uv, normal, 4.0);
    EndPrimitive();
    emitVertex(leftWingPoints[1], uv, normal, 4.0);
    emitVertex(leftWingPoints[2], uv, normal, 4.0);
    emitVertex(leftWingPoints[3], uv, normal, 4.0);
    EndPrimitive();
    
    // 繪製右翼（兩個三角形）
    emitVertex(rightWingPoints[0], uv, normal, 4.0);
    emitVertex(rightWingPoints[3], uv, normal, 4.0);
    emitVertex(rightWingPoints[1], uv, normal, 4.0);
    EndPrimitive();
    emitVertex(rightWingPoints[1], uv, normal, 4.0);
    emitVertex(rightWingPoints[3], uv, normal, 4.0);
    emitVertex(rightWingPoints[2], uv, normal, 4.0);
    EndPrimitive();
    
    // 繪製中央結點（兩個三角形）
    emitVertex(knotPoints[0], uv, normal, 4.0);
    emitVertex(knotPoints[1], uv, normal, 4.0);
    emitVertex(knotPoints[3], uv, normal, 4.0);
    EndPrimitive();
    emitVertex(knotPoints[1], uv, normal, 4.0);
    emitVertex(knotPoints[2], uv, normal, 4.0);
    emitVertex(knotPoints[3], uv, normal, 4.0);
    EndPrimitive();
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
    vec3 triNormal = normalize(cross(
        RawPos[1] - RawPos[0],
        RawPos[2] - RawPos[0]
    ));
    for (int i = 0; i < 3; i++) {
        emitVertex(RawPos[i], TexCoord[i], triNormal, 0.0);
    }
    EndPrimitive();

    // 2. 大拇指鑽石生長效果
    int fingerIdx = getFingerIndex(centerUV);
    bool isNailArea = (centerUV.y < 0.08 && centerUV.y > 0.01);
    
    bool isGrowing = (fingerIdx == activeFinger && patternProgress > 0.01);
    bool isFinished = (fingerIdx > 0 && fingerIdx < 6 && fingerPainted[fingerIdx] == 1);
    
    // 只在大拇指 (fingerIdx == 1) 生成鑽石，且必須在指甲區域且法向量向上
    if (showPattern > 0 && isNailArea && fingerIdx == 1 && (isGrowing || isFinished)) {
        vec3 normal = normalize(cross(
            RawPos[1] - RawPos[0],
            RawPos[2] - RawPos[0]
        ));
        
        // 只在朝上的面生成鑽石（避免手指背面生長）
        if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(17.9128, 83.2331))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress;
            
            // 控制鑽石密度與生長進度
            if (hash < currentProgress * 0.5) {
                // 建立局部座標系
                vec3 tangent = normalize(RawPos[1] - RawPos[0]);
                if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent));
                if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                
                // 鑽石參數：大小與高度隨進度增長
                float normalizedHash = fract(hash * 7.1234);
                float baseRadius = mix(0.04, 0.09, normalizedHash) * currentProgress;
                float height = mix(0.1, 0.25, normalizedHash) * currentProgress;
                
                // 從表面稍微抬起避免 z-fighting
                vec3 basePos = centerRaw + normal * 0.01;
                
                emitDiamond(basePos, normal, tangent, bitangent, baseRadius, height, centerUV);
            }
        }
    }
    
    // 3. 食指金字塔爆炸效果 (fingerIdx == 2)
    if (showPattern > 0 && isNailArea && fingerIdx == 2 && (isGrowing || isFinished)) {
        vec3 normal = normalize(cross(
            RawPos[1] - RawPos[0],
            RawPos[2] - RawPos[0]
        ));
        
        if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(23.4567, 65.7891))) * 43758.5453);
            float currentProgress = isFinished ? 1.0 : patternProgress;
            
            // 每個三角形都可能生成金字塔
            if (hash < currentProgress * 0.6) {
                emitExplodingPyramid(RawPos[0], RawPos[1], RawPos[2], normal,
                                    TexCoord[0], TexCoord[1], TexCoord[2], hash);
            }
        }
    }
    
    // 4. 中指旋轉星星效果 (fingerIdx == 3)
    if (showPattern > 0 && isNailArea && fingerIdx == 3 && (isGrowing || isFinished)) {
        vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
        if (normal.y > 0.5) {
            float hash = fract(sin(dot(centerUV, vec2(31.4159, 27.1828))) * 43758.5453);
            // [關鍵] 確保完成後密度一致
            float threshold = 0.5; 
            if (hash < threshold) {
                vec3 tangent = normalize(RawPos[1] - RawPos[0]);
                if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent));
                if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                float starSize = mix(0.06, 0.12, fract(hash * 3.7));
                // 呼叫更新後的函式，傳入 isFinished 狀態
                emitRotatingStar(centerRaw, normal, tangent, bitangent, starSize, centerUV, hash, isFinished);
            }
        }
    }
    
    // 5. 小指蝴蝶結效果 (fingerIdx == 5) - 單一中央蝴蝶結
    if (showPattern > 0 && isNailArea && fingerIdx == 5 && (isGrowing || isFinished)) {
        vec3 normal = normalize(cross(RawPos[1] - RawPos[0], RawPos[2] - RawPos[0]));
        if (normal.y > 0.5) {
            // 只在指甲中心區域生成一個蝴蝶結
            float distToCenter = distance(centerUV, vec2(centerUV.x < 0.5 ? 0.05 : 0.95, 0.05));
            
            // 只有最靠近中心的三角形才生成蝴蝶結
            if (distToCenter < 0.02) {
                float currentProgress = isFinished ? 1.0 : patternProgress;
                
                vec3 tangent = normalize(RawPos[1] - RawPos[0]);
                if (length(tangent) < 1e-4) tangent = vec3(1.0, 0.0, 0.0);
                vec3 bitangent = normalize(cross(normal, tangent));
                if (length(bitangent) < 1e-4) bitangent = vec3(0.0, 1.0, 0.0);
                
                // 中央蝴蝶結較大
                float bowSize = 0.2;
                float seed = 0.5; // 固定種子確保一致性
                emitBowTie(centerRaw, normal, tangent, bitangent, bowSize, centerUV, seed, isFinished);
            }
        }
    }
}
