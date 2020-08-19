//
//  MetalVideoProcessEraseRightTransition.metal
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
    } FadeTransitionUniform;

    constant float strength=0.1;

    fragment half4 morph(TwoInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  constant FadeTransitionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mag_filter:: linear,
        min_filter:: linear,
        address:: clamp_to_zero);
        float progress = uniform.tweenFactor;
        float2 uv = fragmentInput.textureCoordinate;
        vec2 p = uv;
        
        vec4 ca = vec4(inputTexture.sample(quadSampler, p));
        vec4 cb = vec4(inputTexture2.sample(quadSampler, p));
        
        vec2 oa = (((ca.rg + ca.b) * 0.5) * 2.0 - 1.0);
        vec2 ob = (((cb.rg + cb.b) * 0.5) * 2.0 - 1.0);
        vec2 oc = mix(oa,ob,0.5) * strength;
        // float progress = clamp(timer, 0.0, 1.0);
        float w0 = progress;
        float w1 = 1.0 - w0;
        
        return mix(inputTexture.sample(quadSampler, p + oc * w0), inputTexture2.sample(quadSampler, p - oc * w1), progress);
    }
}
