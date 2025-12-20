#version 330 core
out vec4 FragColor;

in vec2 gTexCoord;
in vec3 gRawPos;
in float isPattern;
in float shouldColor;

uniform sampler2D handTexture;
uniform int activeFinger;
uniform float patternProgress;
uniform int fingerPainted[6];
uniform float purplePaintProgress;

vec3 getNailColor(int idx) {
    if (idx == 1 || idx == 4 || idx == 5) return vec3(0.8, 0.5, 0.9); // 紫色 (拇指、無名指、小指)
    return vec3(0.95, 0.95, 0.95); // 白色 (食指、中指)
}

int getFingerIndex(vec2 uv) {
    if (uv.y < 0.1) {
        // 根據你的截圖重新映射
        // 左手（X < 0.5）
        if (uv.x < 0.5) {
            if (uv.x < 0.1) return 5;       // 最左邊 = 小指
            else if (uv.x < 0.2) return 4;  // 無名指
            else if (uv.x < 0.3) return 3;  // 中指
            else if (uv.x < 0.4) return 2;  // 食指
            else return 1;                   // 拇指
        }
        // 右手（X >= 0.5）
        else {
            if (uv.x < 0.6) return 1;       // 拇指
            else if (uv.x < 0.7) return 2;  // 食指
            else if (uv.x < 0.8) return 3;  // 中指
            else if (uv.x < 0.9) return 4;  // 無名指
            else return 5;                   // 小指
        }
    }
    return 0;
}

void main() {
    // 紫色閃光
    if (isPattern > 1.5) {
        FragColor = vec4(0.9, 0.4, 1.0, 1.0); // 亮紫色閃光
        return;
    }

    // 花紋
    if (isPattern > 0.5) {
        FragColor = vec4(1.0, 0.8, 0.3, 1.0);
        return;
    }

    vec4 texColor = texture(handTexture, gTexCoord);
    vec3 finalColor = texColor.rgb;

    // 獲取手指編號
    int fIdx = getFingerIndex(gTexCoord);

    if (fIdx > 0) {
        // 判斷是否應該上色
        bool shouldPaint = (fingerPainted[fIdx] == 1 || activeFinger == fIdx);

        if (shouldPaint) {
            vec3 nailColor = getNailColor(fIdx);

            // 計算進度
            float t = (fingerPainted[fIdx] == 1) ? 1.0 : patternProgress;
            float blend = smoothstep(0.0, 1.0, t);

            // 混合顏色
            finalColor = mix(texColor.rgb, nailColor, blend * 0.85);

            // 添加高光
            float spec = pow(1.0 - abs(gTexCoord.y - 0.05), 8.0) * 0.3;
            finalColor += spec * blend;
        }

        // P鍵觸發的紫色漸變（從指甲根部逐漸塗向指尖）
        if (purplePaintProgress > 0.0) {
            vec3 purpleColor = vec3(0.7, 0.3, 0.85); // 深紫色

            // 計算漸進式塗抹效果 - 從指尖(y=0.0)到根部(y=0.1)
            // 將 y 座標標準化到 0-1 範圍，其中 1 是指尖，0 是根部
            float nailPos = gTexCoord.y / 0.1;
            nailPos = clamp(nailPos, 0.0, 1.0);

            // 創建移動的塗抹前沿 - 從指尖開始塗
            float paintFront = purplePaintProgress * 1.3;

            // 使用更寬的過渡帶，讓塗抹效果更明顯
            float paintAmount = smoothstep(paintFront + 0.3, paintFront - 0.1, nailPos);

            // 混合紫色
            finalColor = mix(finalColor, purpleColor, paintAmount * 0.9);

            // 添加紫色光澤效果，只在已塗抹區域顯示
            float gloss = pow(1.0 - abs(gTexCoord.y - 0.05), 6.0) * 0.4;
            finalColor += vec3(0.5, 0.2, 0.6) * gloss * paintAmount;
        }
    }

    FragColor = vec4(finalColor, texColor.a);
}
