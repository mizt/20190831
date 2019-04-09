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
    outVert.pos = pos[vid];
    outVert.texcoord = float2(texcoord[vid][0],1-texcoord[vid][1]);
    return outVert;
}

constexpr sampler map(coord::normalized, address::clamp_to_edge, filter:: nearest);
constexpr sampler src(coord::normalized, address::clamp_to_edge, filter:: linear);
    
fragment float4 fragmentShader(VertInOut inFrag[[stage_in]],constant FragmentShaderArguments &args[[buffer(0)]]) {
    
    float2 resolution = args.resolution[0];
    
    
    float wet = fmod(args.time[0]*2.0,2.0);
    //float dry = 0.0;
    if(wet>1.0) wet = 1.0 -(wet-1.0);
    float dry = 1.0-wet; 

    float4  xy = args.map.sample(map,inFrag.texcoord);
    
    float x = ((((int(xy.a*255.0))<<8|(int(xy.b*255.0)))-32767.)*0.25)/(resolution.x-1.0);
    float y = ((((int(xy.g*255.0))<<8|(int(xy.r*255.0)))-32767.)*0.25)/(resolution.y-1.0);
    
    return float4(args.texture.sample(src,vec2(inFrag.texcoord.x*dry+x*wet,inFrag.texcoord.y*dry+y*wet)));
   
}