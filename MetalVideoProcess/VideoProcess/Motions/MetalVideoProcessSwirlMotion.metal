//
//  swirlMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace swirlMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        float2 iResolution;
        
    } MotionUniform;
    
    fragment half4 swirlMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g + uniform.roi.a * 0.5);
        
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 uv = fragmentInput.textureCoordinate2;
        
        float2 tempUv = uv - center;
        float theta = atan2(tempUv.y, tempUv.x);
        float r = length(tempUv);
        theta = theta + r * 20.0 * (1. - uniform.factor);
        uv = float2(r * cos(theta), r * sin(theta)) + center;
        
        half4 fgCol = inputTexture2.sample(quadSampler, uv);
        
        return half4(mix(bgCol.rgb, fgCol.rgb, fgCol.a), fgCol.a);
    }
}


