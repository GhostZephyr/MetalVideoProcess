//
//  zoomOutMotion.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

namespace zoomOutMotion {
    typedef struct
    {
        float factor;
        float4 roi;
        //float2 iResolution;
    } MotionUniform;
    
    fragment half4 zoomOutMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        float2 center = float2(uniform.roi.r + uniform.roi.b * 0.5, uniform.roi.g + uniform.roi.a * 0.5);
        float2 uv = fragmentInput.textureCoordinate2;
        
        half4 fgCol = inputTexture2.sample(quadSampler, (uv - center) * (1. + uniform.factor)  + center);
        
        return half4(mix(bgCol.rgb, fgCol.rgb, fgCol.a), fgCol.a);
    }
}


