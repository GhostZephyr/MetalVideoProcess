//
//  rotateMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace rotateMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        float2 iResolution;
        
    } MotionUniform;
    
    fragment half4 rotateMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g + uniform.roi.a * 0.5);
        
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 uv = fragmentInput.textureCoordinate2;
        
        float rotCorner = uniform.factor * 25.1327408;
        float2 rot = float2(cos(rotCorner), sin(rotCorner));
        
        uv = (uv - center) * uniform.iResolution;
        uv = float2(rot.x * uv.x + rot.y * uv.y, -rot.y * uv.x + rot.x * uv.y);
        uv = uv / uniform.iResolution + center;
        
        half4 fgCol = inputTexture2.sample(quadSampler, uv);
        
        return half4(mix(bgCol.rgb, fgCol.rgb, fgCol.a), fgCol.a);
    }
}


