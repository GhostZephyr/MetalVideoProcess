#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

typedef struct
{
    float tweenFactor;
} FadeTransitionUniform;

fragment half4 shanBai(TwoInputVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                    constant FadeTransitionUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    
    half4 moveInText = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    half4 moveOutTex = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    float curve = 0.0;
    half4 outputTex = moveInText;

    float process = uniform.tweenFactor * 2.0;
    if (process < 1.0) {
        curve = process;
        outputTex = half4(moveInText.rgb + curve, moveInText.a);
    } else {
        curve = 2.0 - process;
        outputTex = half4(moveOutTex.rgb + curve, moveOutTex.a);
    }
    return outputTex;
}
