//
//  File.metal
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/21.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

typedef struct
{
    float factor;
    float4 roi;
} MotionUniform;

fragment half4 fadeInMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                            texture2d<half> inputTexture [[texture(0)]],
                            texture2d<half> inputTexture2 [[texture(1)]],
                            constant MotionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2;
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    
    
    return half4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * half(uniform.factor)), textureColor.a);
}

fragment half4 fadeOutMotion(TwoInputVertexIO fragmentInput [[stage_in]],
                             texture2d<half> inputTexture [[texture(0)]],
                             texture2d<half> inputTexture2 [[texture(1)]],
                             constant MotionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2;
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    
    
    return half4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * half(1.0 - uniform.factor)), textureColor.a);
}
