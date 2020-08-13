//
//  mirrorRotateMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace mirrorRotateMotion {
    typedef struct
    {
        float factor;
        float4 roi;
    } MotionUniform;
    
    fragment half4 mirrorRotateMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g + uniform.roi.a * 0.5);
        float2 uv = fragmentInput.textureCoordinate2;
        
        float2 tempUv = uv;
        float curve = uniform.factor;
        half4 outCol = half4(0.0);
        if (curve < 0.5) {
            tempUv = float2((tempUv.x - center.x) * -(1. + curve * 200.0) + center.x, uv.y);
            outCol = inputTexture2.sample(quadSampler, tempUv.xy);
        } else {
            tempUv = float2((tempUv.x - center.x) * (1. + (1.0 - curve) * 200.0) + center.x, uv.y);
            outCol = inputTexture2.sample(quadSampler, tempUv.xy);
        }
        
        return half4(bgCol.rgb * (1. - outCol.a) + outCol.rgb, outCol.a);
    }
}


