//
//  shader.metal
//  MetalShaders
//  默认的Shader
//  Created by Renzhu Wang on 11/25/19.
//  Copyright (c) 2015 Lixuan Zhu. All rights reserved.
//
#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct {
    vector_float3 position;
    vector_float2 texCoord;
} OrpheusVertexIn;

typedef struct {
    vector_float2 resolution;
    float globalTime;
    int quality;
} OrpheusUniformIn;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} OrpheusVertexOut;

typedef struct
{
    float3x3 colorConversionMatrix;
} YUVConversionUniform;

vertex SingleInputVertexIO oneInputVertex(const device packed_float2 *position [[buffer(0)]],
                                          const device packed_float2 *texturecoord [[buffer(1)]],
                                          uint vid [[vertex_id]])
{
    SingleInputVertexIO outputVertices;
    
    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    
    return outputVertices;
}

fragment half4 passthroughFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]])
{
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: mirrored_repeat);
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    return color;
}

vertex TwoInputVertexIO twoInputVertex(const device packed_float2 *position [[buffer(0)]],
                                       const device packed_float2 *texturecoord [[buffer(1)]],
                                       const device packed_float2 *texturecoord2 [[buffer(2)]],
                                       uint vid [[vertex_id]])
{
    TwoInputVertexIO outputVertices;
    
    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    outputVertices.textureCoordinate2 = texturecoord2[vid];

    return outputVertices;
}


vertex OrpheusVertexOut vertexShader(const device OrpheusVertexIn *vertices [[buffer(0)]],
                                     uint vid [[vertex_id]]) {
    OrpheusVertexOut out;
    out.position = float4(vertices[vid].position, 1.0);
    out.texCoord = vertices[vid].texCoord;
    return out;
}

fragment float4 passthrough(OrpheusVertexOut in [[stage_in]],
                                    constant OrpheusUniformIn &uniformIn [[buffer(0)]],
                                    texture2d<half> inputTexture0 [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter:: linear,
                                     min_filter:: linear);
    float4 color = float4(inputTexture0.sample(textureSampler, in.texCoord));
    return color;
}

fragment half4 colorSwizzleFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).bgra;
    
    return color;
}
