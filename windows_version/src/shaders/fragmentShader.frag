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

vec3 getNailColor(int idx) {
    if (idx == 1 || idx == 4 || idx == 5) return vec3(0.8, 0.5, 0.9); // 紫色
    return vec3(0.95, 0.95, 0.95); // 白色
}

bool isNailColor(vec3 c) {
    // 根據你的貼圖調準此閾值
    return (c.r > 0.6 && c.g < 0.6); 
}

void main() {
    if (isPattern > 0.5) {
        FragColor = vec4(1.0, 0.8, 0.3, 1.0); // 金色花紋
        return;
    }

    vec4 texColor = texture(handTexture, gTexCoord);
    vec3 finalColor = texColor.rgb;

    // 判斷區域
    if (shouldColor > 0.5 && isNailColor(texColor.rgb)) {
        // 重新獲取一次手指編號以確定顏色
        // 這裡需要稍微寬鬆一點的 UV 判斷
        int fIdx = 0;
        if (gTexCoord.x < 0.2) fIdx = 1;
        else if (gTexCoord.x < 0.4) fIdx = 2;
        else if (gTexCoord.x < 0.6) fIdx = 3;
        else if (gTexCoord.x < 0.8) fIdx = 4;
        else fIdx = 5;

        vec3 nailColor = getNailColor(fIdx);
        
        // 關鍵：如果這根手指已經畫完了(fingerPainted==1)，t 直接就是 1.0
        float t = (fingerPainted[fIdx] == 1) ? 1.0 : patternProgress;
        float blend = smoothstep(0.0, 1.0, t);
        
        finalColor = mix(texColor.rgb, nailColor, blend * 0.85);
        
        // 加點反光
        float spec = pow(1.0 - abs(gTexCoord.y - 0.9), 5.0);
        finalColor += spec * 0.2 * blend;
    }

    FragColor = vec4(finalColor, texColor.a);
}