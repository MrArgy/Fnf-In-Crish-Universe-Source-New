#pragma header
#define BLOOM_THRESHOLD 0.5
#define BLOOM_INTENSITY 1.3
#define DIRT_INTENSITY 5
#ifdef ICU_MOBILE
#define BLUR_ITERATIONS 2
#define BLUR_SUBDIVISIONS 12
#else
#define BLUR_ITERATIONS 5
#define BLUR_SUBDIVISIONS 48
#endif
#define BLUR_SIZE 0.03

vec3 getHDR(vec3 tex) {
    return max((tex - BLOOM_THRESHOLD) * BLOOM_INTENSITY, 0.0);
}

vec3 gaussian(sampler2D sampler, vec2 uv) {
    vec3 sum = vec3(0.0);
        
    for(int i = 1; i <= BLUR_ITERATIONS; i++) {
        float angle = 360.0 / float(BLUR_SUBDIVISIONS);
        for(int j = 0; j < BLUR_SUBDIVISIONS; j++) {
            float dist = BLUR_SIZE * (float(i+1) / float(BLUR_ITERATIONS));
            float s = sin(angle * float(j));
            float c = cos(angle * float(j));
            sum += getHDR(texture2D(sampler, uv + vec2(c,s)*dist).xyz);
        }
    }
    sum /= float(BLUR_ITERATIONS * BLUR_SUBDIVISIONS);
    return sum * BLOOM_INTENSITY;
}

vec3 blend(vec3 a, vec3 b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 tx = texture2D(bitmap, uv);
    gl_FragColor.rgb = gaussian(bitmap, uv) * (1.0 - float(tx.rgb));
    gl_FragColor.a = tx.a;
    gl_FragColor.rgb = blend(tx.rgb, gl_FragColor.rgb);
}
