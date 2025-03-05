//
//  ConvMatrix.h
//  ComputerGraphics_1
//
//  Created by I3artek on 05/03/2025.
//

#ifndef ConvMatrix_h
#define ConvMatrix_h

//#include <stdint.h>

struct ConvMatrix {
    int8_t values[9][9];
    uint8_t size_x;
    uint8_t size_y;
    uint8_t anchor_x;
    uint8_t anchor_y;
    uint32_t divisor;
};

typedef struct ConvMatrix ConvMatrix;

#endif /* ConvMatrix_h */
