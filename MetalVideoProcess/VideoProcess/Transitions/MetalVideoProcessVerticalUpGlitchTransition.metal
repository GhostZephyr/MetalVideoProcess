//
//  MetalVideoProcessVerticalGlitchTransition.metal
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
    
    float easeInOutQuint(float t)
    {
        return t < 0.5 ? 16.0 * t * t * t * t * t : 1.0 + 16.0 * (--t) * t * t * t * t;
    }

    void main() {
        
    }

    
    fragment half4 verticalupGlitch(TwoInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  constant FadeTransitionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mag_filter:: linear,
        min_filter:: linear,
        address:: clamp_to_zero);
        float progress = uniform.tweenFactor;
        float2 uv = fragmentInput.textureCoordinate;
        vec2 resolution = uniform.iResolution;
        
        float mProgress = 1.0 - easeInOutQuint(progress);
        if(uv.y < mProgress)
            return inputTexture.sample(quadSampler, uv + vec2(0.0, 1.0 - mProgress));
        else
            return inputTexture2.sample(quadSampler, uv - vec2(0.0, mProgress));
    }
}
