#version 330 core
out vec4 FragColor;

in vec2 gTexCoord;
in vec3 gRawPos;
in vec3 gNormal;
in float isPattern;
in float shouldColor;

uniform sampler2D handTexture;
uniform int activeFinger;
uniform float patternProgress;
uniform int fingerPainted[6];

// 愛心形狀函數 (SDF)
float sdHeart(vec2 p) {
    p.x = abs(p.x);
    if (p.y + p.x > 1.0)
        return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0)/4.0;
    return sqrt(min(dot(p - vec2(0.00, 1.00), p - vec2(0.00, 1.00)),
                    dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}

// 指甲底色
vec3 getNailColor(int idx) {
    if (idx == 1) return vec3(0.85, 0.65, 0.95);      // 拇指：粉紫
    else if (idx == 2) return vec3(0.95, 0.95, 0.95); // 食指：白
    else if (idx == 3) return vec3(0.55, 0.4, 0.8);   // 中指：深紫
    else if (idx == 4) return vec3(0.98, 0.75, 0.85); // 無名指：淺粉
    else if (idx == 5) return vec3(0.92, 0.92, 0.98); // 小指：冷調銀白
    else return vec3(0.85, 0.85, 0.92);
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
    // 1. 幾何體 (星星/鑽石/蝴蝶結)
    if (isPattern > 0.5) {
        vec3 normal = normalize(gNormal);
        vec3 viewDir = normalize(vec3(0.0, 5.0, 10.0) - gRawPos);
        vec3 lightDir = normalize(vec3(5.0, 10.0, 15.0) - gRawPos);
        
        vec3 baseColor;
        if (isPattern > 3.5) {
            // 4.0 = 小指蝴蝶結：根據texture的IMG_4381.jpeg調色
            baseColor = vec3(0.9, 0.7, 0.9); // 淡紫粉色，配合texture
        } else if (isPattern > 2.5) {
            baseColor = vec3(0.95, 0.96, 0.98); // 中指銀星
        } else if (isPattern > 1.5) {
            baseColor = vec3(0.95, 0.95, 0.95); // 食指白鑽
        } else {
            baseColor = vec3(0.7, 0.4, 0.85); // 拇指紫水晶
        }

        vec3 ambient = baseColor * 0.3;
        float diff = max(dot(normal, lightDir), 0.0);
        vec3 diffuse = baseColor * diff * 0.4;
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(normal, halfDir), 0.0), 64.0);
        vec3 specular = vec3(1.0) * spec * 1.5;
        float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 3.0);
        
        vec3 rimLight;
        // 蝴蝶結特殊光效
        if (isPattern > 3.5) {
            rimLight = vec3(0.95, 0.8, 0.95) * fresnel * 1.2; // 淡紫粉邊緣光，配合texture色調
        } else {
            rimLight = vec3(1.0) * fresnel * 0.9;
        }
            
        vec3 finalColor = ambient + diffuse + specular + rimLight;
        float alpha = (isPattern > 3.5) ? 0.95 : ((isPattern > 2.5) ? 0.9 : 0.85);
        FragColor = vec4(finalColor, alpha);
        return;
    }

    // 2. 指甲彩繪
    vec4 texColor = texture(handTexture, gTexCoord);
    vec3 finalColor = texColor.rgb;
    int fIdx = getFingerIndex(gTexCoord);
    
    if (fIdx > 0) {
        bool shouldPaint = (fingerPainted[fIdx] == 1 || activeFinger == fIdx);
        
        if (shouldPaint) {
            vec3 nailColor = getNailColor(fIdx);
            float t = (fingerPainted[fIdx] == 1) ? 1.0 : patternProgress;
            float blend = smoothstep(0.0, 1.0, t);
            finalColor = mix(texColor.rgb, nailColor, blend * 0.85);
            
            // --- 無名指 (Ring Finger) ---
            if (fIdx == 4) {
                vec3 viewDir = normalize(vec3(0.0, 5.0, 10.0) - gRawPos);
                vec3 normal = normalize(gNormal);
                
                // [貓眼修正] 使用 pow(0.5) 讓光帶更寬更柔，消除銳利線條
                float offset = viewDir.x * 0.6 + viewDir.z * 0.1;
                float catEyePos = (gTexCoord.x - 0.5) + offset;
                float band = 1.0 - smoothstep(0.0, 0.6, abs(catEyePos)); // 範圍加大到 0.6
                band = pow(band, 0.6); // 指數調低，邊緣更霧
                
                vec3 basePink = vec3(0.98, 0.75, 0.85);
                vec3 mistyWhite = vec3(1.0, 0.92, 0.95);
                vec3 catEyeColor = mix(basePink, mistyWhite, band * 0.7);
                finalColor = mix(finalColor, catEyeColor, band * 0.8 * blend);
                
                // [愛心修正] 調整座標計算，確保愛心不會跑出界
                vec2 uv = gTexCoord;
                // 判斷左手(X<0.5)或右手，給予更準確的中心位移
                float centerX = (uv.x < 0.5) ? 0.15 : 0.85; 
                
                // 這裡我們稍微微調 Y 軸，原本 0.05 改為 0.06 試試
                uv -= vec2(centerX, 0.06); 
                uv.x *= 1.5; 
                uv *= 20.0; // [關鍵] 數字變小(25->20) = 愛心變大！
                uv.y -= 0.5; 
                
                float d = sdHeart(uv);
                float heartMask = 1.0 - smoothstep(0.0, 0.1, d); 
                if (heartMask > 0.0) {
                    finalColor = mix(finalColor, vec3(1.0, 1.0, 1.0), heartMask * blend);
                }
            } 
            // --- 小拇指 (Pinky) ---
            else if (fIdx == 5) {
                // [亮片修正] 顆粒感修正 (Cell-based Glitter)
                // 將 UV 放大 30 倍，形成網格，讓亮片變大顆
                vec2 gridUV = gTexCoord * 30.0; 
                vec2 gridID = floor(gridUV);
                
                // 每個格子算一個隨機數
                float noise = fract(sin(dot(gridID, vec2(12.9898, 78.233))) * 43758.5453);
                
                // 只有隨機數 > 0.7 的格子才發光 (30% 的覆蓋率，避免全白)
                if (noise > 0.7) {
                    // 雷射變色：根據格子位置變色，而不是像素位置
                    vec3 holoColor = 0.5 + 0.5 * cos(gTexCoord.y * 10.0 + vec3(0, 2, 4));
                    // 讓光更亮
                    finalColor += holoColor * 1.8 * blend; 
                }
                
                // 額外加上一層細微的珠光，避免沒亮片的地方太單調
                float sheen = pow(1.0 - abs(gTexCoord.x - (gTexCoord.x < 0.5 ? 0.05 : 0.95)), 4.0); 
                finalColor += vec3(0.1, 0.1, 0.2) * sheen * blend;

            } else {
                float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.3;
                finalColor += spec * blend;
            }
        }
    }

    FragColor = vec4(finalColor, texColor.a);
}