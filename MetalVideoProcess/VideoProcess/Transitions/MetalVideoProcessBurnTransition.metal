//
//  MetalVideoProcessFadeTransition.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

#define vec2 float2
#define vec3 float3
#define vec4 float4
typedef struct
{
    float tweenFactor;
} FadeTransitionUniform;

half4 TextureSource(vec2 uv, texture2d<half> inputTexture, sampler quadSampler)
{
    return inputTexture.sample(quadSampler, uv);
}

half4 TextureTarget(vec2 uv, texture2d<half> inputTexture2, sampler quadSampler)
{
    return inputTexture2.sample(quadSampler, uv);
}

float Hash(vec2 p)
{
    vec3 p2 = vec3(p.xy, 1.0);
    return fract(sin(dot(p2, vec3(37.1, 61.7, 12.4))) * 3758.5453123);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f *= f * (3.0 - 2.0 * f);

    return mix(mix(Hash(i + vec2(0., 0.)), Hash(i + vec2(1., 0.)),f.x),
        mix(Hash(i + vec2(0., 1.)), Hash(i + vec2(1., 1.)),f.x),
        f.y);
}

float fbm(vec2 p)
{
    float v = 0.0;
    v += noise(p * 1.) * .5;
    v += noise(p * 2.) * .25;
    v += noise(p * 4.) * .125;
    return v;
}

fragment half4 burnTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant FadeTransitionUniform& uniform [[buffer(1)]])
{
    float iTime = uniform.tweenFactor;
    constexpr sampler quadSampler;

    vec2 uv = fragmentInput.textureCoordinate;
    
    half4 src = inputTexture.sample(quadSampler, uv);
    
    half4 tgt = inputTexture2.sample(quadSampler, uv);
    
    half4 col = src;
    
    uv.x -= 1.5;
    
    float ctime = iTime * 1.5;
    
    // 斜向坐标，并以fbm作为边界随机偏置
    float d = uv.x + uv.y * 0.5 + 0.5 * fbm(uv * 15.1) + ctime * 1.3;
    
    //黑色阴影
    if (d >0.35) col = clamp(col -(d - 0.35) * 10., 0.0, 1.0);
    
    if (d >0.47) {
        //模拟火焰，火焰🔥颜色为 vec4(1.5, 0.5, 0.0, 1.0)， 其中1.5为增加亮度
        if (d < 0.5 ) col += half4((d - 0.4) * 33.0 * 0.5 *(noise(100. * uv + vec2(- ctime * 2., 0.)))* vec4(1.5, 0.5, 0.0, 1.0));
        else col += tgt; }
    
    return col;

}
