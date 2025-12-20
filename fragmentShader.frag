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

// 指甲底色設定
vec3 getNailColor(int idx) {
    if (idx == 1) return vec3(0.85, 0.65, 0.95);      // 拇指：粉紫
    else if (idx == 2) return vec3(0.95, 0.95, 0.95); // 食指：白
    else if (idx == 3) return vec3(0.55, 0.4, 0.8);   // 中指：深紫
    else if (idx == 4) return vec3(1.0, 0.82, 0.88);  // 無名指：粉白底
    
    // [★ 修正重點] 這裡一定要改！原本是 vec3(0.92, 0.92, 0.98) 會變白
    // 改成 vec3(1.0, 0.8, 0.9) 才會是粉紅色
    else if (idx == 5) return vec3(0.55, 0.4, 0.8);    
    
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
        // 4.0 = 小指 3D 蝴蝶結 (Pink Bow)
        if (isPattern > 4.5) {
            // 5.0 = 小指銀白色細閃粉 - 純銀色,無彩虹
            
            // 固定銀白色,不受任何計算影響
            vec3 pureWhite = vec3(0.95, 0.95, 0.95);
            
            // 簡單的亮度變化,但保持白色
            float brightness = 0.7 + max(dot(normal, lightDir), 0.0) * 0.3;
            
            vec3 finalColor = pureWhite * brightness;
            FragColor = vec4(finalColor, 0.92);
        } else if (isPattern > 3.5) {
            baseColor = vec3(1.0, 0.6, 0.8); // 亮粉色蝴蝶結
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
        if (isPattern > 3.5) {
            rimLight = vec3(0.95, 0.8, 0.95) * fresnel * 1.2;
        } else {
            rimLight = vec3(1.0) * fresnel * 0.9;
        }
            
        vec3 finalColor = ambient + diffuse + specular + rimLight;
        float alpha = (isPattern > 3.5) ? 0.95 : ((isPattern > 2.5) ? 0.9 : 0.85);
        FragColor = vec4(finalColor, alpha);
        return;
    }

    // 2. 指甲彩繪邏輯
    vec4 texColor = texture(handTexture, gTexCoord);
    vec3 finalColor = texColor.rgb;
    int fIdx = getFingerIndex(gTexCoord);
    
    if (fIdx > 0) {
        bool shouldPaint = (fingerPainted[fIdx] == 1 || activeFinger == fIdx);
        
        if (shouldPaint) {
            vec3 nailColor = getNailColor(fIdx);
            
            // 狀態持久化
            float t = (fingerPainted[fIdx] == 1) ? 1.0 : patternProgress;
            float blend = smoothstep(0.0, 1.0, t);
            
            // 基礎上色 (所有手指都先上底色)
            finalColor = mix(texColor.rgb, nailColor, blend * 0.85);
            
            // --- 無名指 (Ring Finger) ---
            if (fIdx == 4) {
                vec3 basePink = vec3(1.0, 0.82, 0.88); 
                
                float distFromCenter = abs(gTexCoord.y - 0.05);
                
                float highlight = pow(clamp(1.0 - distFromCenter * 10.0, 0.0, 1.0), 10.0) * 0.18;
                
                float finalSpec = highlight * blend;

                // 3. 混合顏色
                finalColor = mix(texColor.rgb, basePink, blend * 0.85);
                
                // 疊加高光
                finalColor += vec3(1.0) * finalSpec;
            }
            // 小指格紋效果
            else if (fIdx == 5) {
                // 格紋參數
                float gridSize = 30.0; // 格子大小
                float lineWidth = 0.08; // 線條粗細
                
                // 計算格紋
                vec2 grid = fract(gTexCoord * gridSize);
                float line = step(1.0 - lineWidth, grid.x) + step(1.0 - lineWidth, grid.y);
                line = min(line, 1.0);
                
                // 格紋顏色：銀白色線條
                vec3 lineColor = vec3(0.85, 0.85, 0.9);
                
                // 混合底色和格紋
                finalColor = mix(finalColor, lineColor, line * blend * 0.6);
                
                // 加上高光
                float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.2;
                finalColor += spec * blend;
            }else {
                // 其他手指的高光
                float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.3;
                finalColor += spec * blend;
            }
        }
    }

    FragColor = vec4(finalColor, texColor.a);
}