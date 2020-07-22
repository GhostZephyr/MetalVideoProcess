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

fragment half4 eraseDownTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant FadeTransitionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    float2 uv = fragmentInput.textureCoordinate;
    half4 input0 = inputTexture.sample(quadSampler, uv);
    half4 input1 = inputTexture2.sample(quadSampler, uv);
    float process = uniform.tweenFactor;
    
//    float curve0 = process * process;
//    float curve1 = 3. * curve0 - 2. * curve0 * process;
    return mix(input0, input1, step(uv.y, process));
}
