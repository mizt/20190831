#include <metal_stdlib>
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

struct VertInOut {
    float4 pos[[position]];
    float2 texcoord[[user(texturecoord)]];
};

struct FragmentShaderArguments {
    device float *time[[id(0)]];
    device float2 *resolution[[id(1)]];
    device float2 *mouse[[id(2)]];
    texture2d<float> texture[[id(3)]];
    texture2d<float> map[[id(4)]];
};

vertex VertInOut vertexShader(constant float4 *pos[[buffer(0)]],constant packed_float2  *texcoord[[buffer(1)]],uint vid[[vertex_id]]) {
    VertInOut outVert;
    
    float4x4 mvp = float4x4(
    float4(1.732051,0.000000,0.000000,0.000000),
    float4(0.000000,1.732051,0.000000,0.000000),
    float4(0.000000,0.000000,1.000200,1.000000),
    float4(0.000000,0.000000,17.123949,17.320507));

   
    outVert.pos = mvp*pos[vid];
    //outVert.pos = pos[vid];
    outVert.texcoord = float2(texcoord[vid][0],1-texcoord[vid][1]);
    return outVert;
}

fragment float4 fragmentShader(VertInOut inFrag[[stage_in]],constant FragmentShaderArguments &args[[buffer(0)]]) {
    constexpr sampler sampler(address::clamp_to_edge, filter::nearest);
    return float4(args.texture.sample(sampler,inFrag.texcoord));
}