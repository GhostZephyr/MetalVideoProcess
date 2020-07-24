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

namespace moveUpMotion {
    typedef struct
    {
        float factor;
        float4 roi;
    } MotionUniform;
    
    fragment half4 moveUpMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                texture2d<half> inputTexture2 [[texture(1)]],
                                constant MotionUniform& uniform [[ buffer(1) ]])
    {
        
        constexpr sampler quadSampler(mip_filter::linear, min_filter::linear, mag_filter::linear, address::clamp_to_zero);
       
        half4 bgCol = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
        
        float2 uv = fragmentInput.textureCoordinate2;
        
        half4 fgCol = inputTexture2.sample(quadSampler, uv - float2(0.0, uniform.roi.b) + float2(0.0, uniform.roi.b * uniform.factor));
        
        return half4(mix(bgCol.rgb, fgCol.rgb, fgCol.a), fgCol.a);
    }
}


