//
//  MetalVideoProcessTransformFilter.metal
//  MetalVideoProcessTransformFilter
//
//  Created by RenZhu Macro on 2020/5/15.
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

typedef struct
{
    float feather;
    float2 iResolution;
    float4x4 mvp;
    
} TransformUniform;

vertex SingleInputVertexIO transformVertex(const device packed_float2 *position [[buffer(0)]],
                                           const device packed_float2 *texturecoord [[buffer(1)]],
                                           uint vid [[vertex_id]],
                                           constant TransformUniform &uniform[[buffer(30)]])
{
    SingleInputVertexIO outputVertices;
    
    outputVertices.position = (uniform.mvp * float4(position[vid] * uniform.iResolution, 0, 1.0));
    outputVertices.position.xy /= uniform.iResolution;
    outputVertices.textureCoordinate = texturecoord[vid];
    
    return outputVertices;
}


fragment half4 transformFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                 texture2d<half> inputTexture [[texture(0)]],
                                 constant TransformUniform &uniform [[ buffer(1) ]],
                                 constant float &iGlobalTime[[buffer(2)]],
                                 constant float &progress[[buffer(3)]])
{
    constexpr sampler textureSampler(mag_filter:: linear,
                                     min_filter:: linear,
                                     address:: clamp_to_zero);
    /*
    float2 onePixel = 3. * uniform.feather / uniform.iResolution;
    
    float4 feather = float4(smoothstep(0.0, onePixel.x, fragmentInput.textureCoordinate.x),
                            smoothstep(1.0, 1.0 - onePixel.x, fragmentInput.textureCoordinate.x),
                            smoothstep(0.0, onePixel.y, fragmentInput.textureCoordinate.y),
                            smoothstep(1.0, 1.0 - onePixel.y, fragmentInput.textureCoordinate.y));
     */
    half4 bgCol = inputTexture.sample(textureSampler, fragmentInput.textureCoordinate);
    //bgCol.a = bgCol.a * feather.x * feather.y * feather.z * feather.a;
    return bgCol;
}
