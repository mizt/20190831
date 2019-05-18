#include <metal_stdlib>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define ivec2 int2
#define ivec3 int3
#define ivec4 int4
#define mat2 float2x2
#define mat3 float3x3
#define mat4 float4x4

#define M_PI 3.1415926535897932384626433832795

float radians(float degrees) {
    return ((1.0f/180.0f)*float(M_PI))*degrees;
}

float4x4 perspective_fov(float fovy,float aspect, float near,float far) {
    float angle  = radians(0.5f * fovy);
    float yScale = 1.0f / tan(angle);
    float xScale = yScale / aspect;
    float zScale = far / (far - near);
    
    float4 P = 0.0f;
    float4 Q = 0.0f;
    float4 R = 0.0f;
    float4 S = 0.0f;
    
    P.x =  xScale;
    Q.y =  yScale;
    R.z =  zScale;
    R.w =  1.0f;
    S.z = -near * zScale;
    
    return float4x4(P, Q, R, S);
}

float4x4 lookAt(float3 eye,float3 center,float3 up) {
 
    simd::float3 zAxis = simd::normalize(center - eye);
    simd::float3 xAxis = simd::normalize(simd::cross(up, zAxis));
    simd::float3 yAxis = simd::cross(zAxis, xAxis);
    
    simd::float4 P;
    simd::float4 Q;
    simd::float4 R;
    simd::float4 S;
    
    P.x = xAxis.x;
    P.y = yAxis.x;
    P.z = zAxis.x;
    P.w = 0.0f;
    
    Q.x = xAxis.y;
    Q.y = yAxis.y;
    Q.z = zAxis.y;
    Q.w = 0.0f;
    
    R.x = xAxis.z;
    R.y = yAxis.z;
    R.z = zAxis.z;
    R.w = 0.0f;
    
    S.x = -simd::dot(xAxis, eye);
    S.y = -simd::dot(yAxis, eye);
    S.z = -simd::dot(zAxis, eye);
    S.w =  1.0f;
    
    return simd::float4x4(P, Q, R, S);
    
} // lookAt

float4x4 inverse(float4x4 m) {
    float
        a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3],
        a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3],
        a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3],
        a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3],

        b00 = a00 * a11 - a01 * a10,
        b01 = a00 * a12 - a02 * a10,
        b02 = a00 * a13 - a03 * a10,
        b03 = a01 * a12 - a02 * a11,
        b04 = a01 * a13 - a03 * a11,
        b05 = a02 * a13 - a03 * a12,
        b06 = a20 * a31 - a21 * a30,
        b07 = a20 * a32 - a22 * a30,
        b08 = a20 * a33 - a23 * a30,
        b09 = a21 * a32 - a22 * a31,
        b10 = a21 * a33 - a23 * a31,
        b11 = a22 * a33 - a23 * a32,

        det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
            
    float4x4 mat = float4x4(
        float4(
            a11 * b11 - a12 * b10 + a13 * b09,
            a02 * b10 - a01 * b11 - a03 * b09,
            a31 * b05 - a32 * b04 + a33 * b03,
            a22 * b04 - a21 * b05 - a23 * b03
        ),
        float4(
            a12 * b08 - a10 * b11 - a13 * b07,
            a00 * b11 - a02 * b08 + a03 * b07,
            a32 * b02 - a30 * b05 - a33 * b01,
            a20 * b05 - a22 * b02 + a23 * b01
        ),
        float4(
            a10 * b10 - a11 * b08 + a13 * b06,
            a01 * b08 - a00 * b10 - a03 * b06,
            a30 * b04 - a31 * b02 + a33 * b00,
            a21 * b02 - a20 * b04 - a23 * b00
        ),
        float4(
            a11 * b07 - a10 * b09 - a12 * b06,
            a00 * b09 - a01 * b07 + a02 * b06,
            a31 * b01 - a30 * b03 - a32 * b00,
            a20 * b03 - a21 * b01 + a22 * b00
        )
    ); 

    return mat * (1./det);
}


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
    
    float4x4 projectionMatrix = perspective_fov(60.,1920./1080.,0.1,1000.);
    float4x4 viewMatrix = lookAt(vec3(0.,0.,10.),vec3(0.,0.,0.),vec3(0.,1.,0.));
    float4x4 modelViewMatrix = viewMatrix * constants.prs_matrix;

    out.position = projectionMatrix * modelViewMatrix * float4(vertex_array[vid].position,1.0);
       
    float color = 0.5+saturate(dot((normalize( inverse(transpose(modelViewMatrix))*float4(vertex_array[vid].normal,0.0))).xyz,-(float3(0,-5,5))))*0.5;
    out.color = half4(color,color,color,1);
        
    return out;
}

fragment half4 fragmentShader(ColorInOut in [[stage_in]]) {
    return in.color;
};
