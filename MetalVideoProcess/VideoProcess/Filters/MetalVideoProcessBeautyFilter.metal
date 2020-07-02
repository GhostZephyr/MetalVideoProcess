//
//  MetalVideoProcessBeautyFilter.metal
//  MetalVideoProcessFilter
//
//  Created by RenZhu Macro on 2020/4/23.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

#define vec4 float4
#define vec3 float3
#define vec2 float2
#define mat2 float2x2
#define mat3 float3x3

constant float3 W = vec3(0.299, 0.587, 0.114);

constant float3x3 saturateMatrix = float3x3
{
    1.1102, -0.0598, -0.061,
    -0.0774, 1.0826, -0.1186,
    -0.0228, -0.0228, 1.1772
};

using namespace metal;

typedef struct
{
    float brightness;
    float2 singleStepOffset;
    float4 params;
} BeautyUniform;

float hardlight(float color) {
    if(color <= 0.5) {
        color = color * color * 2.0;
    } else {
        color = 1.0 - ((1.0 - color)*(1.0 - color) * 2.0);
    }
    return color;
}

fragment half4 beautyFilter(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant BeautyUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    float2 fixCoordinate =
    float2(fragmentInput.textureCoordinate.x,
           fragmentInput.textureCoordinate.y);
    float2 singleStepOffset = uniform.singleStepOffset;
//    float2 singleStepOffset = float2(0.0027778, 0.0015625);
    vec2 blurCoordinates[24];

    blurCoordinates[0] = fixCoordinate.xy + singleStepOffset * vec2(0.0, -10.0);
    blurCoordinates[1] = fixCoordinate.xy + singleStepOffset * vec2(0.0, 10.0);
    blurCoordinates[2] = fixCoordinate.xy + singleStepOffset * vec2(-10.0, 0.0);
    blurCoordinates[3] = fixCoordinate.xy + singleStepOffset * vec2(10.0, 0.0);

    blurCoordinates[4] = fixCoordinate.xy + singleStepOffset * vec2(5.0, -8.0);
    blurCoordinates[5] = fixCoordinate.xy + singleStepOffset * vec2(5.0, 8.0);
    blurCoordinates[6] = fixCoordinate.xy + singleStepOffset * vec2(-5.0, 8.0);
    blurCoordinates[7] = fixCoordinate.xy + singleStepOffset * vec2(-5.0, -8.0);

    blurCoordinates[8] = fixCoordinate.xy + singleStepOffset * vec2(8.0, -5.0);
    blurCoordinates[9] = fixCoordinate.xy + singleStepOffset * vec2(8.0, 5.0);
    blurCoordinates[10] = fixCoordinate.xy + singleStepOffset * vec2(-8.0, 5.0);
    blurCoordinates[11] = fixCoordinate.xy + singleStepOffset * vec2(-8.0, -5.0);

    blurCoordinates[12] = fixCoordinate.xy + singleStepOffset * vec2(0.0, -6.0);
    blurCoordinates[13] = fixCoordinate.xy + singleStepOffset * vec2(0.0, 6.0);
    blurCoordinates[14] = fixCoordinate.xy + singleStepOffset * vec2(6.0, 0.0);
    blurCoordinates[15] = fixCoordinate.xy + singleStepOffset * vec2(-6.0, 0.0);

    blurCoordinates[16] = fixCoordinate.xy + singleStepOffset * vec2(-4.0, -4.0);
    blurCoordinates[17] = fixCoordinate.xy + singleStepOffset * vec2(-4.0, 4.0);
    blurCoordinates[18] = fixCoordinate.xy + singleStepOffset * vec2(4.0, -4.0);
    blurCoordinates[19] = fixCoordinate.xy + singleStepOffset * vec2(4.0, 4.0);

    blurCoordinates[20] = fixCoordinate.xy + singleStepOffset * vec2(-2.0, -2.0);
    blurCoordinates[21] = fixCoordinate.xy + singleStepOffset * vec2(-2.0, 2.0);
    blurCoordinates[22] = fixCoordinate.xy + singleStepOffset * vec2(2.0, -2.0);
    blurCoordinates[23] = fixCoordinate.xy + singleStepOffset * vec2(2.0, 2.0);

    
    
    half4 color = inputTexture.sample(quadSampler, fixCoordinate);
    
    float sampleColor = color.g * 22.0;
    
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[0]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[1]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[2]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[3]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[4]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[5]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[6]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[7]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[8]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[9]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[10]).g;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[11]).g;
    
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[12]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[13]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[14]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[15]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[16]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[17]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[18]).g * 2.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[19]).g * 2.0;

    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[20]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[21]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[22]).g * 3.0;
    sampleColor += inputTexture.sample(quadSampler, blurCoordinates[23]).g * 3.0;

    sampleColor = sampleColor / 62.0;

    float3 centralColor = float3(inputTexture.sample(quadSampler, fixCoordinate).rgb);
    
    float highpass = centralColor.g - sampleColor + 0.5;

    for(int i = 0; i < 5; i++) {
        highpass = hardlight(highpass);
    }
    float lumance = dot(centralColor, W);
    float alpha = pow(lumance, uniform.params.r);

    vec3 smoothColor = centralColor + (centralColor - vec3(highpass)) * alpha * 0.1;

    smoothColor.r = clamp(pow(smoothColor.r, uniform.params.g), 0.0, 1.0);
    smoothColor.g = clamp(pow(smoothColor.g, uniform.params.g), 0.0, 1.0);
    smoothColor.b = clamp(pow(smoothColor.b, uniform.params.g), 0.0, 1.0);

    vec3 lvse = vec3(1.0) - (vec3(1.0) - smoothColor) * (vec3(1.0) - centralColor);
    vec3 bianliang = max(smoothColor, centralColor);
    vec3 rouguang = 2.0 * centralColor * smoothColor + centralColor * centralColor -
                    2.0 * centralColor*centralColor * smoothColor;
    
    float4 rsColor = vec4(mix(centralColor, lvse, alpha), 1.0);
    
    rsColor.rgb = mix(rsColor.rgb, bianliang, alpha);
    rsColor.rgb = mix(rsColor.rgb, rouguang, uniform.params.b);
//    return half4(half3(rsColor.rgb), 1.0);
//    vec3 satcolor = rsColor.rgb * saturateMatrix;
//     return half4(half3(satcolor.rgb), 1.0);
    
//    rsColor.rgb = mix(rsColor.rgb, satcolor, uniform.params.a);
    rsColor.rgb = rsColor.rgb + uniform.brightness;
    
    return half4(half3(rsColor.rgb), 1.0);
}
