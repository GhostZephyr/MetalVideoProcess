//
//  MetalVideoProcessCubeTransition.metal
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Vender/Render/Base/OperationShaderTypes.h"
namespace cube{
#define vec2 float2
#define vec3 float3
#define vec4 float4
    typedef struct
    {
        float tweenFactor;
    } FadeTransitionUniform;
    
    constant float persp = .7;
    constant float unzoom = .3;
    constant float reflection = .4;
    constant float floating = 3.;
    constant vec2 boundMin = vec2(0.0);
    constant vec2 boundMax = vec2(1.0);
    constant half4 black = half4(0.0);
    vec2 project(vec2 p)
    {
        return p * vec2(1, -1.2) + vec2(0, -floating / 100.);
    }
    
    bool inBounds(float2 p) {
        
        float2 compare0 = step(boundMin, p);
        float2 compare1 = step(p, boundMax);
        if (compare0.x * compare0.y * compare1.x * compare1.y > 0.5) {
            return true;
        } else {
            return false;
        }
    }
    
    half4 bgColor(float2 p, float2 pfr, float2 pto, texture2d<half> from, texture2d<half> to, sampler samp) {
        half4 c = half4(0, 0, 0, 0);
        pfr = project(pfr);
        if (inBounds(pfr)) {
            c += mix(black, from.sample(samp, vec2(pfr.x, 1.0 - pfr.y)), reflection * mix(1.0, 0.0, pfr.y));
        }
        
        pto = project(pto);
        if (inBounds(pto)) {
            c += mix(black, to.sample(samp, vec2(pto.x, 1. - pto.y)), reflection * mix(1.0, 0.0, pto.y));
        }
        return c;
    }
    
    // p : the position
    // persp : the perspective in [ 0, 1 ]
    // center : the xcenter in [0, 1] \ 0.5 excluded
    vec2 xskew(vec2 p, float persp, float center)
    {
        float x = mix(p.x, 1.-p.x, center);
        return (
                ( vec2( x, (p.y - .5 * (1. - persp) * x) / (1. + (persp - 1.) * x))
                 - vec2(.5 - fabs(center - .5), 0)
                 )
                * vec2(.5 / fabs(center - .5) * (center < 0.5 ? 1. : -1.), 1.) + vec2(center<0.5 ? 0. : 1., .0)
                );
    }
    
    
    fragment half4 cubeTransition(TwoInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  texture2d<half> inputTexture2 [[texture(1)]],
                                  constant FadeTransitionUniform& uniform [[buffer(1)]])
    {
        constexpr sampler quadSampler;
        
        vec2 uv = fragmentInput.textureCoordinate;
        
        float progress = uniform.tweenFactor;
        
        vec2 op = vec2(uv.x, 1. - uv.y);
        
        float uz = unzoom * 2.0 * (0.5 - fabs(0.5 - progress));
        vec2 p = -uz * 0.5 + (1.0 + uz) * op;
        vec2 fromP = xskew((p - vec2(progress, 0.0)) / vec2(1.0 - progress, 1.0),
                           1.0-mix(progress, 0.0, persp),
                           0.0
                           );
        vec2 toP = xskew(
                         p / vec2(progress, 1.0),
                         mix(pow(progress, 2.0), 1.0, persp),
                         1.0
                         );
        if (inBounds(fromP))
        {
            
            return inputTexture.sample(quadSampler, vec2(fromP.x, 1. - fromP.y));
        }
        else if (inBounds(toP))
        {
            
            return inputTexture2.sample(quadSampler, vec2(toP.x, 1. - toP.y));
        }
        else
        {
            return bgColor(op, fromP, toP, inputTexture, inputTexture2, quadSampler);
        }
        
    }
}

