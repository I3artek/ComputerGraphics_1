//
//  Filters.metal
//  ComputerGraphics_1
//
//  Created by I3artek on 24/02/2025.
//
// https://medium.com/@garejakirit/a-beginners-guide-to-metal-shaders-in-swiftui-5e98ef3cb222

#include <metal_stdlib>
using namespace metal;

kernel void kernelShader(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = inTexture.read(gid);
        float value = dot(inColor.rgb, float3(0.299, 0.587, 0.114));
        float4 grayColor(value, value, value, 1.0);
        float4 outColor = mix(grayColor, inColor, 1);
        outTexture.write(outColor, gid);
    }

// ------------------ The color values are not RGBA
// ------------------ They are BGRA

kernel void inversion(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = inTexture.read(gid);
        float4 outColor = float4(1.0 - inColor[0], 1.0 - inColor[1], 1.0 - inColor[2], 1.0);
        outTexture.write(outColor, gid);
    }

kernel void identity(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = inTexture.read(gid);
        outTexture.write(inColor, gid);
    }

kernel void swap_red_blue(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
    {
        float4 inColor = inTexture.read(gid);
        float4 outColor = float4(inColor[2], inColor[1], inColor[0], inColor[3]);
        outTexture.write(outColor, gid);
    }
