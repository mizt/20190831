#pragma once
#import <simd/simd.h>

namespace AAPL {
    struct constants_t {
        simd::float4x4 modelview_projection_matrix;
        simd::float4x4 normal_matrix;
    } __attribute__ ((aligned (256)));
}
