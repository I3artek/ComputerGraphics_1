//
//  Filters.metal
//  ComputerGraphics_1
//
//  Created by I3artek on 24/02/2025.
//
// https://medium.com/@garejakirit/a-beginners-guide-to-metal-shaders-in-swiftui-5e98ef3cb222

#include <metal_stdlib>
using namespace metal;

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

kernel void brightness_correction(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    // this must be a float value here already
    // if a division is put there (like 130/256), it does not work
    float offset = -0.2;
    float4 inColor = inTexture.read(gid);
    float4 outColor = float4(0.0, 0.0, 0.0, 1.0);
    float newColor;
    for(int i = 0; i <= 2; i++)
    {
        newColor = inColor[i] + offset;
        if(newColor < 0.0)
            outColor[i] = 0.0;
        else if (newColor > 1.0)
            outColor[i] = 1.0;
        else
            outColor[i] = newColor;
    }
    outTexture.write(outColor, gid);
}

kernel void gamma_correction(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    // this must be a float value here already
    // if a division is put there (like 130/256), it does not work
    float gamma = 2.0;
    float4 inColor = inTexture.read(gid);
    float4 outColor = float4(0.0, 0.0, 0.0, 1.0);
    for(int i = 0; i <= 2; i++)
    {
        outColor[i] = pow(inColor[i], gamma);
    }
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

kernel void matrix3x3(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    uint x = gid[0];
    uint y = gid[1];
    // anchor is the same as anchor offset from top-left corner
    uint2 anchor = uint2(1, 1);
    uint2 anchor_offset = uint2(1, 1);
    uint start_x = x + anchor_offset[0];
    uint start_y = y + anchor_offset[1];
    uint m[3][3] = {};
    float4 sum = float4(0.0, 0.0, 0.0, 0.0);
    float4 tmp;
    for(int i = 0; i < 3; i++)
    {
        for(uint j = 0; j < 3; j++)
        {
            tmp = inTexture.read(uint2(start_x + i, start_y + j));
            sum += float4(tmp[0] * m[i][j], tmp[1] * m[i][j], tmp[2] * m[i][j], 0.0);
        }
    }
    
    float4 inColor = inTexture.read(gid);
    float4 outColor = float4(inColor[2], inColor[1], inColor[0], inColor[3]);
    outTexture.write(outColor, gid);
}

kernel void move(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid - uint2(1,1));
    outTexture.write(inColor, gid);
}
