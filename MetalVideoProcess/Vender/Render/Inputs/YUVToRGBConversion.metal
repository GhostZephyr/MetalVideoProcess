#include <metal_stdlib>
#include "../Base/OperationShaderTypes.h"
using namespace metal;

typedef struct
{
    float3x3 colorConversionMatrix;
} YUVConversionUniform;

fragment half4 yuvConversionFullRangeFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                     texture2d<half> inputTexture [[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant YUVConversionUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r;
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).rg - half2(0.5, 0.5);

    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}

fragment half4 yuvConversionVideoRangeFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                                              texture2d<half> inputTexture [[texture(0)]],
                                              texture2d<half> inputTexture2 [[texture(1)]],
                                              constant YUVConversionUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half3 yuv;
    yuv.x = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).r - (16.0/255.0);
    yuv.yz = inputTexture2.sample(quadSampler, fragmentInput.textureCoordinate).ra - half2(0.5, 0.5);
    
    half3 rgb = half3x3(uniform.colorConversionMatrix) * yuv;
    
    return half4(rgb, 1.0);
}

constant float3 ColorOffsetFullRange = float3(0.0, -0.5, -0.5);

kernel void yuv2rgb(texture2d<float, access::read> y_tex      [[ texture(0) ]],
                         texture2d<float, access::read> uv_tex     [[ texture(1) ]],
                         texture2d<float, access::write> bgr_tex   [[ texture(2) ]],
                         uint2 gid [[thread_position_in_grid]])
{
    
    float3 yuv = float3(y_tex.read(gid).r, uv_tex.read(gid/2).rg) + ColorOffsetFullRange;
    
    const float3x3 kColorConversion601Default = {
        {1.164,  1.164,  1.164},
        {0.0,    -0.392, 2.017},
        {1.596,  -0.813, 0.0},
    };

    bgr_tex.write(float4(float3(kColorConversion601Default * yuv), 1.0), gid);
}
