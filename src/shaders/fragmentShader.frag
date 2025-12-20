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

// 設定每根手指的指甲底色
vec3 getNailColor(int idx) {
    if (idx == 1) return vec3(0.85, 0.65, 0.95);      // 大拇指：粉紫色
    else if (idx == 2) return vec3(0.95, 0.95, 0.95); // 食指：白色
    else if (idx == 3) return vec3(0.55, 0.4, 0.8);   // 中指：深紫色
    else if (idx == 4) return vec3(1.0, 0.82, 0.88);  // 無名指：粉白色
    else if (idx == 5) return vec3(0.55, 0.4, 0.8);   // 小拇指：深紫色
    else return vec3(0.85, 0.85, 0.92);               // 預設
}

// 根據 UV 座標判斷手指索引
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
    // === 1. 處理 3D 裝飾幾何體（從 geometry shader 生成） ===
    if (isPattern > 0.5) {
        vec3 normal = normalize(gNormal);
        vec3 viewDir = normalize(vec3(0.0, 5.0, 10.0) - gRawPos);
        vec3 lightDir = normalize(vec3(5.0, 10.0, 15.0) - gRawPos);
        
        vec3 baseColor;
        
        // isPattern 值用於區分不同類型的 3D 裝飾
        if (isPattern > 4.5) {
            // 未使用（預留給小拇指的銀白色細閃粉）
            vec3 pureWhite = vec3(0.95, 0.95, 0.95);
            float brightness = 0.7 + max(dot(normal, lightDir), 0.0) * 0.3;
            vec3 finalColor = pureWhite * brightness;
            FragColor = vec4(finalColor, 0.92);
            return;
        } else if (isPattern > 3.5) {
            baseColor = vec3(1.0, 0.6, 0.8);        // 小拇指：粉色蝴蝶結
        } else if (isPattern > 2.5) {
            baseColor = vec3(0.95, 0.96, 0.98);     // 中指：銀白色星星
        } else if (isPattern > 1.5) {
            baseColor = vec3(0.95, 0.95, 0.95);     // 食指：白色金字塔
        } else {
            baseColor = vec3(0.7, 0.4, 0.85);       // 大拇指：紫色鑽石
        }

        // Blinn-Phong 光照模型
        vec3 ambient = baseColor * 0.3;
        float diff = max(dot(normal, lightDir), 0.0);
        vec3 diffuse = baseColor * diff * 0.4;
        vec3 halfDir = normalize(lightDir + viewDir);
        float spec = pow(max(dot(normal, halfDir), 0.0), 64.0);
        vec3 specular = vec3(1.0) * spec * 1.5;
        
        // Fresnel 邊緣光效果
        float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 3.0);
        vec3 rimLight;
        if (isPattern > 3.5) {
            rimLight = vec3(0.95, 0.8, 0.95) * fresnel * 1.2;  // 蝴蝶結粉色邊緣光
        } else {
            rimLight = vec3(1.0) * fresnel * 0.9;               // 其他白色邊緣光
        }
            
        vec3 finalColor = ambient + diffuse + specular + rimLight;
        float alpha = (isPattern > 3.5) ? 0.95 : ((isPattern > 2.5) ? 0.9 : 0.85);
        FragColor = vec4(finalColor, alpha);
        return;
    }

    // === 2. 處理指甲彩繪（底色和特殊效果） ===
    vec4 texColor = texture(handTexture, gTexCoord);
    vec3 finalColor = texColor.rgb;
    int fIdx = getFingerIndex(gTexCoord);
    
    if (fIdx > 0) {
        // 判斷該手指是否需要上色
        bool shouldPaint = (fingerPainted[fIdx] == 1 || activeFinger == fIdx);
        
        if (shouldPaint) {
            vec3 nailColor = getNailColor(fIdx);
            
            // 根據完成狀態決定混合進度
            float t = (fingerPainted[fIdx] == 1) ? 1.0 : patternProgress;
            float blend = smoothstep(0.0, 1.0, t);
            
            // 基礎底色混合
            finalColor = mix(texColor.rgb, nailColor, blend * 0.85);
            
            // === 無名指特殊效果：漸層高光 ===
            if (fIdx == 4) {
                vec3 basePink = vec3(1.0, 0.82, 0.88); 
                
                // 計算到指甲中心的距離
                float distFromCenter = abs(gTexCoord.y - 0.05);
                
                // 生成高光漸層
                float highlight = pow(clamp(1.0 - distFromCenter * 10.0, 0.0, 1.0), 10.0) * 0.18;
                float finalSpec = highlight * blend;

                // 應用底色和高光
                finalColor = mix(texColor.rgb, basePink, blend * 0.85);
                finalColor += vec3(1.0) * finalSpec;
            }
            // === 小拇指特殊效果：格紋 ===
            else if (fIdx == 5) {
                float gridSize = 30.0;   // 格子大小
                float lineWidth = 0.08;  // 線條粗細
                
                // 計算格紋（每個格子的邊緣）
                vec2 grid = fract(gTexCoord * gridSize);
                float line = step(1.0 - lineWidth, grid.x) + step(1.0 - lineWidth, grid.y);
                line = min(line, 1.0);
                
                // 格紋線條顏色
                vec3 lineColor = vec3(0.85, 0.85, 0.9);
                
                // 混合底色和格紋
                finalColor = mix(finalColor, lineColor, line * blend * 0.6);
                
                // 添加高光
                float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.2;
                finalColor += spec * blend;
            }
            // === 其他手指：基礎高光 ===
            else {
                float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.3;
                finalColor += spec * blend;
            }
        }
    }

    FragColor = vec4(finalColor, texColor.a);
}