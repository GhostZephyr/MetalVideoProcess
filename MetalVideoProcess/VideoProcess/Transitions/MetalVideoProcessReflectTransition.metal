//
//  MetalVideoProcessReflectTransition.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"

typedef struct
{
    float tweenFactor;
} FadeTransitionUniform;


constant float reflection = .3;
constant float perspective = .1;
constant float depth = 3.;
 
constant half4 black = half4(0.0, 0.0, 0.0, 1.0);
constant float2 boundMin = float2(0.0, 0.0);
constant float2 boundMax = float2(1.0, 1.0);
 
bool inBounds (float2 p) {
 
    float2 compare0 = step(boundMin, p);
    float2 compare1 = step(p, boundMax);
    if (compare0.x * compare0.y * compare1.x * compare1.y > 0.5) {
        return true;
    } else {
        return false;
    }
}
 
float2 project (float2 p) {
  return p * float2(1.0, -1.2) + float2(0.0, -0.02);
}
 
half4 bgColor (float2 p, float2 pfr, float2 pto, texture2d<half> from, texture2d<half> to, sampler samp) {
      half4 c = black;
      pfr = project(pfr);
      if (inBounds(pfr)) {
        c += mix(black, from.sample(samp, pfr), reflection * mix(1.0, 0.0, pfr.y));
      }

      pto = project(pto);
      if (inBounds(pto)) {
        c += mix(black, to.sample(samp, pto), reflection * mix(1.0, 0.0, pto.y));
      }
      return c;
}

fragment half4 reflectTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> from [[texture(0)]],
                              texture2d<half> to [[texture(1)]],
                              constant FadeTransitionUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler(mag_filter:: linear,
    min_filter:: linear,
    address:: clamp_to_zero);
    float2 uv = fragmentInput.textureCoordinate;
    float iTime = uniform.tweenFactor;
    float progress = iTime;
    float2 pfr = float2(-1.);
    float2 pto = float2(-1.);
   
    float size = mix(1.0, depth, progress);
    float persp = perspective * progress;
    float2 p = float2(uv.x, 1.0 - uv.y);
    pfr = (p + float2(-0.0, -0.5)) * float2(size / (1.0 - perspective * progress), size / (1.0 - size * persp * p.x)) + float2(0.0, 0.5);
   
    size = mix(1.0, depth, 1. - progress);
    persp = perspective * (1. - progress);
    pto = (p + float2(-1.0, -0.5)) * float2(size / (1.0 - perspective * (1.0 - progress)), size / (1.0 - size * persp * (0.5 - p.x))) + float2(1.0, 0.5);
   
    bool fromOver = progress < 0.5;
    half4 fragColor = half4(0.0);
    if (fromOver) {
      if (inBounds(pfr)) {
          fragColor = from.sample(quadSampler, float2(pfr.x, 1. - pfr.y));
      }
      else if (inBounds(pto)) {
          fragColor = to.sample(quadSampler, float2(pto.x, 1. - pto.y));
      }
      else {
          fragColor = bgColor(p, pfr, pto, from, to, quadSampler);
      }
    }
    else {
      if (inBounds(pto)) {
          
          fragColor = to.sample(quadSampler, float2(pto.x, 1. - pto.y));
      }
      else if (inBounds(pfr)) {
          
          fragColor = from.sample(quadSampler, float2(pfr.x, 1. - pfr.y));
      }
      else {
          fragColor = bgColor(p, pfr, pto, from, to, quadSampler);
      }
    }
    return fragColor;
}
