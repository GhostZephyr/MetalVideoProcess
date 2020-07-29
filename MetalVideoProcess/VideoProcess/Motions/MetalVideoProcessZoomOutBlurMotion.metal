//
//  zoomOutBluMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace zoomOutBlurMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        float2 iResolution;
    } MotionUniform;
    
    fragment half4 zoomOutBlurMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g + uniform.roi.a * 0.5);
        float time = clamp(uniform.factor * 2.0, 0.0, 1.0);
        float2 uv = fragmentInput.textureCoordinate2;
        
        uv = (uv - center);
        uv = uv * (0.4 + 0.6 * uniform.factor) + center;
        
        float2 dir = float2(uv - center) * 0.5 * (1. - time);
        
        half4 fgCol = half4(0.0);
        for(float i = 0.0; i < 1.0; i = i + 0.2) {
            fgCol += inputTexture2.sample(quadSampler, uv + dir * i);
        }
            
        fgCol /= 5.0;
        return half4(bgCol.rgb * (1. - fgCol.a) + fgCol.rgb, fgCol.a);
    }
}
