//
//  MetalVideoProcessCircleEraseTransition.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace morph {
#define vec2 float2
#define vec3 float3
#define vec4 float4
    
    typedef struct
    {
        float tweenFactor;
        float2 iResolution;
    } FadeTransitionUniform;
    
    fragment half4 circleErase(TwoInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  constant FadeTransitionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mag_filter:: linear,
        min_filter:: linear,
        address:: clamp_to_zero);
        float progress = uniform.tweenFactor;
        float2 uv = fragmentInput.textureCoordinate;
        
        float mProgress = 1.0 - progress;
        vec2 resolution = uniform.iResolution;
        if(distance(uv * resolution, vec2(0.5,0.5) * resolution) < mProgress * length(resolution) * 0.5)
            return inputTexture.sample(quadSampler, uv);
        else
            return inputTexture2.sample(quadSampler, uv);

    }
}
