#version 330 core
out vec4 FragColor;
in vec2 TexCoord;

uniform float time;

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 多重採樣抗鋸齒
float smoothNoiseAA(vec2 p) {
    vec2 dx = dFdx(p);
    vec2 dy = dFdy(p);
    float samples = max(length(dx), length(dy));
    
    if (samples < 1.0) {
        return smoothNoise(p);
    }
    
    float result = 0.0;
    int numSamples = min(int(samples * 2.0), 4);
    float offset = 0.25;
    
    for (int i = 0; i < numSamples; i++) {
        for (int j = 0; j < numSamples; j++) {
            vec2 samplePos = p + vec2(float(i), float(j)) * offset / float(numSamples);
            result += smoothNoise(samplePos);
        }
    }
    
    return result / float(numSamples * numSamples);
}

void main() {
    vec2 uv = TexCoord * 8.0;
    
    // 垂直木紋
    float woodPattern = smoothNoiseAA(vec2(uv.x * 0.15, uv.y * 4.0));
    woodPattern += smoothNoiseAA(vec2(uv.x * 0.3, uv.y * 8.0)) * 0.6;
    woodPattern += smoothNoiseAA(vec2(uv.x * 0.6, uv.y * 16.0)) * 0.3;
    woodPattern /= 1.9;
    
    // 年輪效果
    float ringFreq = uv.y * 10.0 + woodPattern * 3.0;  // 降低頻率
    
    // aliasing
    float gradient = fwidth(ringFreq) * 2.0;
    float rings;
    if (gradient > 0.01) {
        float phase = ringFreq / gradient;
        rings = (sin(ringFreq) + gradient * cos(ringFreq)) / (1.0 + gradient);
        rings = rings * 0.5 + 0.5;
        rings = smoothstep(0.2, 0.8, rings);
    } else {
        rings = sin(ringFreq) * 0.5 + 0.5;
    }
    rings = pow(rings, 0.7);
    
    vec3 darkWood = vec3(0.25, 0.18, 0.14);
    vec3 midWood = vec3(0.38, 0.28, 0.22);
    vec3 lightWood = vec3(0.48, 0.36, 0.28);
    
    // 混合顏色
    vec3 woodColor = mix(darkWood, midWood, woodPattern);
    woodColor = mix(woodColor, lightWood, rings * 0.4);
    
    // 添加細節紋理
    float detail = smoothNoiseAA(uv * 30.0) * 0.04;
    woodColor += detail;
    
    // 添加漸層
    float vignette = 1.0 - (TexCoord.y - 0.5) * 0.12;
    woodColor *= vignette;
    
    FragColor = vec4(woodColor, 1.0);
}