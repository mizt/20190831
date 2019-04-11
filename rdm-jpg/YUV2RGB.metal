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
};

vertex VertInOut vertexShader(constant float4 *pos[[buffer(0)]],constant packed_float2  *texcoord[[buffer(1)]],uint vid[[vertex_id]]) {
    VertInOut outVert;
    outVert.pos = pos[vid];
    outVert.texcoord = float2(texcoord[vid][0],1-texcoord[vid][1]);
    return outVert;
}

fragment float4 fragmentShader(VertInOut inFrag[[stage_in]],constant FragmentShaderArguments &args[[buffer(0)]]) {
    constexpr sampler quadSampler(coord::normalized, filter::linear);
    float4 rgba = args.texture.sample(quadSampler,inFrag.texcoord);

    int y = rgba.r*255.0-16.0;
    int u = rgba.g*255.0-128.0;
    int v = rgba.b*255.0-128.0;
    
    int r = 1192*y+1634*v;
    int g = 1192*y-401*u-832*v;
    int b = 1192*y+2065*u;
    
    r = (r<0)?0:(r>=261120)?0xFF:(r>>10);
    g = (g<0)?0:(g>=261120)?0xFF:(g>>10);
    b = (b<0)?0:(b>=261120)?0xFF:(b>>10);
    
    return float4(r/255.,g/255.,b/255.,rgba.a);
}

