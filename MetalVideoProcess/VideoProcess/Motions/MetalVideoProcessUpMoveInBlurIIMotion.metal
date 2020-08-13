//
//  upMoveInBlurIIMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace upMoveInBlurIIMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        float2 iResolution;
    } MotionUniform;
    
    fragment half4 upMoveInBlurIIMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 center = float2(uniform.roi.r + uniform.roi.b, uniform.roi.g + uniform.roi.a * 0.5);
        float time = uniform.factor;
        float2 uv = fragmentInput.textureCoordinate2;
        
        float rotCorner = -(1. - time) * 1.5707963;
        float2 rot = float2(cos(rotCorner), sin(rotCorner));
        
        uv = (uv - center) * uniform.iResolution;
        uv = float2(rot.x * uv.x + rot.y * uv.y, -rot.y * uv.x + rot.x * uv.y);
        uv = uv / uniform.iResolution + center;
        
        float2 dir = float2(uv - center) * 0.5 * (1. - time);
        dir = -float2(rot.x * dir.x + rot.y * dir.y, -rot.y * dir.x + rot.x * dir.y) * 0.6;
        
        half4 fgCol = half4(0.0);
        for(float i = 0.0; i < 1.0; i = i + 0.1) {
            fgCol += inputTexture2.sample(quadSampler, uv + dir * i);
        }
            
        fgCol /= 10.0;
        return half4(bgCol.rgb * (1. - fgCol.a) + fgCol.rgb, fgCol.a);
    }
}
