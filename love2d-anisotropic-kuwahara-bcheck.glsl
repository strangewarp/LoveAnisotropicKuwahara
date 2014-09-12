
////////// Original code credits: //////////
// by Jan Eric Kyprianidis <www.kyprianidis.com>
// https://code.google.com/p/gpuakf/source/browse/glsl/kuwahara.glsl
////////////////////////////////////////////

// This shader is modified to be compatible with LOVE2D's quirky shader engine!
// Modified by Christian D. Madsen
// https://github.com/strangewarp/LoveAnisotropicKuwahara

extern Image src;
extern float radius;
extern float window_width;
extern float window_height;

vec4 effect (vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {

    vec4 outpix;

    int rad = int(radius);

    vec2 src_size = vec2(int(window_width), int(window_height));
    vec2 uv = gl_FragCoord.xy / src_size;
    number n = number((rad + 1) * (rad + 1));

    vec3 compare = Texel(src, uv / src_size).rgb;
    bool diffpix = false;

    ////////////////////////////////////////////////////////////////////////////////
    // Bilateral difference-check, to speed up the processing of large flat areas //
    ////////////////////////////////////////////////////////////////////////////////
    for (int j = -rad; j <= rad; ++j) {
        if (Texel(src, uv + vec2(0,j) / src_size).rgb != compare) {
            diffpix = true;
            break;
        }
    }
    if (!diffpix) {
        for (int i = -rad; i <= rad; ++i) {
            if (Texel(src, uv + vec2(i,0) / src_size).rgb != compare) {
                diffpix = true;
                break;
            }
        }
    }
    if (!diffpix) {
        return vec4(Texel(src, uv / src_size).rgb, 1.0);
    }
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    vec3 m[4];
    vec3 s[4];
    for (int k = 0; k < 4; ++k) {
        m[k] = vec3(0.0);
        s[k] = vec3(0.0);
    }

    for (int j = -rad; j <= 0; ++j)  {
        for (int i = -rad; i <= 0; ++i)  {
            vec3 c = Texel(src, uv + vec2(i,j) / src_size).rgb;
            m[0] += c;
            s[0] += c * c;
        }
    }

    for (int j = -rad; j <= 0; ++j)  {
        for (int i = 0; i <= rad; ++i)  {
            vec3 c = Texel(src, uv + vec2(i,j) / src_size).rgb;
            m[1] += c;
            s[1] += c * c;
        }
    }

    for (int j = 0; j <= rad; ++j)  {
        for (int i = 0; i <= rad; ++i)  {
            vec3 c = Texel(src, uv + vec2(i,j) / src_size).rgb;
            m[2] += c;
            s[2] += c * c;
        }
    }

    for (int j = 0; j <= rad; ++j)  {
        for (int i = -rad; i <= 0; ++i)  {
            vec3 c = Texel(src, uv + vec2(i,j) / src_size).rgb;
            m[3] += c;
            s[3] += c * c;
        }
    }

    number min_sigma2 = 1e+2;
    for (int k = 0; k < 4; ++k) {
        m[k] /= n;
        s[k] = abs(s[k] / n - m[k] * m[k]);
        number sigma2 = s[k].r + s[k].g + s[k].b;
        if (sigma2 < min_sigma2) {
            min_sigma2 = sigma2;
            outpix = vec4(m[k], 1.0);
        }
    }

    return outpix;

}
