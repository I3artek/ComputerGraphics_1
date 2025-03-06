//
//  Filters.metal
//  ComputerGraphics_1
//
//  Created by I3artek on 24/02/2025.
//
// https://medium.com/@garejakirit/a-beginners-guide-to-metal-shaders-in-swiftui-5e98ef3cb222

#include <metal_stdlib>
#include "ConvMatrix.h"
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

kernel void matrix_filter(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]],
                         constant ConvMatrix *matrix [[buffer(0)]])
{
    float4 inColor;
    float4 outColor = float4(0.0, 0.0, 0.0, 1.0);
    uint2 pos;
    for(int i = 0; i < matrix->size_x; i++)
    {
        for(int j = 0; j < matrix->size_y; j++)
        {
            pos = uint2(gid[0] + i - matrix->anchor_x, gid[1] + j - matrix->anchor_y);
            inColor = inTexture.read(pos);
            outColor += matrix->values[i][j] * inColor;
        }
    }
    outColor = float4(outColor[0] / matrix->divisor, outColor[1] / matrix->divisor, outColor[2] / matrix->divisor, 1.0);
    outTexture.write(outColor, gid);
}

kernel void pixelize_filter(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]],
                            constant uint32_t *psize [[buffer(0)]])
{
    float4 inColor;
    float4 outColor = float4(0.0, 0.0, 0.0, 1.0);
    uint2 pos;
    uint pos_x;
    uint pos_y;
    uint size = *psize;
    uint divisor = size * size;
    
    pos_x = gid[0] - (gid[0] % size);
    pos_y = gid[1] - (gid[1] % size);
    
    for(uint i = 0; i < size; i++) {
        for(uint j = 0; j < size; j++) {
            pos = uint2(pos_x + i, pos_y + j);
            inColor = inTexture.read(pos);
            outColor += inColor;
        }
    }
    outColor = float4(outColor[0] / divisor, outColor[1] / divisor, outColor[2] / divisor, 1.0);
    
    //outColor = float4(outColor[0] / matrix->divisor, outColor[1] / matrix->divisor, outColor[2] / matrix->divisor, 1.0);
    outTexture.write(outColor, gid);
}

kernel void move(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]])
{
    float4 inColor = inTexture.read(gid - uint2(1,1));
    outTexture.write(inColor, gid);
}
