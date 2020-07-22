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

typedef struct
{
    float tweenFactor;
} FadeTransitionUniform;

fragment half4 mirrorRotateTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant FadeTransitionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    float2 uv = fragmentInput.textureCoordinate;
    
    float process = uniform.tweenFactor;
    
    float curve0 = process * process;
    float curve1 = 3. * curve0 - 2. * curve0 * process;
    float2 tempUv = uv;
    
    half4 outCol = half4(0.0);
    if (curve1 < 0.5) {
        tempUv = float2((tempUv.x - 0.5) * (1. + curve1 * 100.0) + 0.5, uv.y);
        outCol = inputTexture.sample(quadSampler, tempUv.xy);
    } else {
        tempUv = float2((tempUv.x - 0.5) * (1. + (1.0 - curve1) * 100.0) + 0.5, uv.y);
        outCol = inputTexture2.sample(quadSampler, tempUv.xy);
    }
    
    return outCol;
}
