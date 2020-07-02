#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

typedef struct
{
    float mixturePercent;
    float blendMode;
} AlphaBlendUniform;

fragment half4 alphaBlend(TwoInputVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant AlphaBlendUniform& uniform [[ buffer(1) ]])
{
    
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    constexpr sampler quadSampler2(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    
    half4 textureColor2 = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate2);
    half4 outputCol = half4(0.0);
    switch(int(uniform.blendMode)) {
        case 0: 
            outputCol = textureColor * (1. - textureColor2.a) + textureColor2;//mix(textureColor, textureColor2, textureColor2.a);
            break;
        case 1: 
            outputCol = half4(textureColor.rgb * textureColor2.a, textureColor.a * textureColor2.a);
            break;
        default: 
            outputCol = mix(textureColor, textureColor2, textureColor2.a);
            break;
    }
    return outputCol;
}
