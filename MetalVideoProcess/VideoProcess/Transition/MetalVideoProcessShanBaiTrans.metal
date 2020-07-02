#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

fragment half4 shanBai(TwoInputVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant float& process[[buffer(3)]])
{
    
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    
    half4 moveInText = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    half4 moveOutTex = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    float curve = 0.0;
    half4 outputTex = moveInText;
    if (process < 0.5) {
        curve = process;
        outputTex = half4(moveInText.rgb + curve, moveInText.a);
    } else {
        curve = 1.0 - process;
        outputTex = half4(moveOutTex.rgb + curve, moveOutTex.a);
    }
    return outputTex;
}
