//
//  MetalVideoProcessColorFilter.metal
//  MetalVideoProcessColorFilter
//
//  Created by wangrenzhu Macro on 2020/5/15.
//  Copyright © 2020 wangrenzhu Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

#define vec4 float4
#define vec3 float3
#define vec2 float2
#define mat2 float2x2
#define mat3 float3x3

using namespace metal;

typedef struct
{
    float strength;
    float4 color;
} Uniform;

fragment half4 colorFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant Uniform &uniform [[ buffer(1) ]])
{
    constexpr sampler textureSampler(mag_filter:: linear,
                                     min_filter:: linear,
                                     address:: clamp_to_zero);
    half4 bgCol = inputTexture.sample(textureSampler, fragmentInput.textureCoordinate);
   
    return mix(bgCol, half4(uniform.color), half(uniform.strength));
}
