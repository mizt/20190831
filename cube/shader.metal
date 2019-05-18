#include <metal_stdlib>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

typedef struct {
	packed_float3 position;
	packed_float3 normal;
} vertex_t;

struct ColorInOut {
    float4 position [[position]];
    half4 color;
};

vertex ColorInOut vertexShader(device vertex_t* vertex_array [[ buffer(0) ]], constant AAPL::constants_t& constants [[ buffer(1) ]], unsigned int vid [[ vertex_id ]]) {
    ColorInOut out;
    
	float4 in_position = float4(float3(vertex_array[vid].position), 1.0);
    out.position = constants.modelview_projection_matrix * in_position;
   
    float3 normal = vertex_array[vid].normal;
    out.color = half4(float4(normal*0.5+0.5,1.0));
    return out;
}

fragment half4 fragmentShader(ColorInOut in [[stage_in]]) {
    return in.color;
};
