//
//  MetalVideoProcessFadeTransition.metal
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

typedef struct
{
    float tweenFactor;
} FadeTransitionUniform;

fragment half4 fadeTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant FadeTransitionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2;
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    
    return half4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * half(uniform.tweenFactor)), textureColor.a);
}
