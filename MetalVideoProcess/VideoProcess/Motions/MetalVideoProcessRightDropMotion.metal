//
//  pendulumMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"
#define PI 3.1415926
namespace rightDropMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        float2 iResolution;
    } MotionUniform;
    
    fragment half4 rightDropMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g);
        float time = cos(uniform.factor * PI * 2.5) * exp(-uniform.factor);
        float2 uv = fragmentInput.textureCoordinate2 + float2(0.5, 0.0) * time;
        
        float2 dir = float2(0.1, 0.0) * time;
       
        half4 fgCol = half4(0.0);
        for(float i = 0.0; i < 1.0; i = i + 0.1) {
            fgCol += inputTexture2.sample(quadSampler, uv + dir * i);
        }
            
        fgCol /= 10.0;
        return half4(bgCol.rgb * (1. - fgCol.a) + fgCol.rgb, fgCol.a);
    }
}
