//
//  OperationShaderTypes.h
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/4/15.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//
#include <metal_stdlib>
using namespace metal;

#ifndef OperationShaderTypes_h
#define OperationShaderTypes_h

// Luminance Constants
constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);  // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham

struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

struct TwoInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};

#endif /* OperationShaderTypes_h */
