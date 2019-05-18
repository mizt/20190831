#pragma once
#import <simd/simd.h>

namespace AAPL {
    struct constants_t {
        simd::float4x4 prs_matrix;
    } __attribute__ ((aligned (256)));
}
