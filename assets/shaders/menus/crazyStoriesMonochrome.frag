#pragma header

void main() {
    vec4 pixel = flixel_texture2D(bitmap, openfl_TextureCoordv);
    float luminance = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    gl_FragColor = vec4(vec3(luminance), pixel.a);
}
