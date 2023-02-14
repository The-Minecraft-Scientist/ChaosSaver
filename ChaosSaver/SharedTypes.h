//
//  SharedTypes.h
//  ChaosSaver
//
//  Created by Charles Liske on 2/13/23.
//

#ifndef SharedTypes_h
#define SharedTypes_h

#include "simd/simd.h"
typedef simd_float3 RBEntry;
struct RBHeader {
    RBEntry *buf;
    uint32_t last;
    uint32_t first;
    uint32_t count;
    uint32_t zeroIndex;
};

#endif /* SharedTypes_h */
