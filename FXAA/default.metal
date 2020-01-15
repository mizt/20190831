// (Tested) Fast Approximate Anti-Aliasing (FXAA) Demo (GLSL)
// https://www.geeks3d.com/20110405/fxaa-fast-approximate-anti-aliasing-demo-glsl-opengl-test-radeon-geforce/3/

#include <metal_stdlib>
using namespace metal;

#define FXAA_SPAN_MAX 8.0
#define FXAA_REDUCE_MUL (1.0/8.0)
#define FXAA_REDUCE_MIN (1.0/128.0)

#define OFFSET_X (1.0/1280.0)
#define OFFSET_Y (1.0/ 720.0)

struct VertInOut {
    float4 pos[[position]];
    float2 texcoord[[user(texturecoord)]];
};

struct FragmentShaderArguments {
    texture2d<float> texture[[id(0)]];
};

vertex VertInOut vertexShader(constant float4 *pos[[buffer(0)]],constant packed_float2  *texcoord[[buffer(1)]],uint vid[[vertex_id]]) {
    VertInOut outVert;
    outVert.pos = pos[vid];
    outVert.texcoord = float2(texcoord[vid][0],1.0-texcoord[vid][1]);
    return outVert;
}

fragment float4 fragmentShader(VertInOut inFrag[[stage_in]],constant FragmentShaderArguments &args[[buffer(0)]]) {
    
    constexpr sampler sampler(address::clamp_to_edge, filter::linear);
    
    float2 texcoordOffset = float2(OFFSET_X,OFFSET_Y);
    
    float2 pos = inFrag.texcoord;

    float3 rgbNW = args.texture.sample(sampler,pos+(float2(-1.0,-1.0)*texcoordOffset)).xyz;
    float3 rgbNE = args.texture.sample(sampler,pos+(float2(+1.0,-1.0)*texcoordOffset)).xyz;
    float3 rgbSW = args.texture.sample(sampler,pos+(float2(-1.0,+1.0)*texcoordOffset)).xyz;
    float3 rgbSE = args.texture.sample(sampler,pos+(float2(+1.0,+1.0)*texcoordOffset)).xyz;
    float3 rgbM  = args.texture.sample(sampler,pos).xyz;
    
    float3 luma = float3(0.299, 0.587, 0.114);
    
    float lumaNW = dot(rgbNW,luma);
    float lumaNE = dot(rgbNE,luma);
    float lumaSW = dot(rgbSW,luma);
    float lumaSE = dot(rgbSE,luma);
    float lumaM  = dot(rgbM ,luma);
	
    float lumaMin = min(lumaM,min(min(lumaNW,lumaNE),min(lumaSW,lumaSE)));
    float lumaMax = max(lumaM,max(max(lumaNW,lumaNE),max(lumaSW,lumaSE)));
	
    float2 dir = float2(
        -((lumaNW+lumaNE)-(lumaSW+lumaSE)),
         ((lumaNW+lumaSW)-(lumaNE+lumaSE))
	);

    float dirReduce = max((lumaNW+lumaNE+lumaSW+lumaSE)*(0.25*FXAA_REDUCE_MUL),FXAA_REDUCE_MIN);
	  
    float rcpDirMin = 1.0/(min(abs(dir.x),abs(dir.y))+dirReduce);
	
    dir = min(float2(FXAA_SPAN_MAX,FXAA_SPAN_MAX),max(float2(-FXAA_SPAN_MAX,-FXAA_SPAN_MAX),dir*rcpDirMin))*texcoordOffset;
		
    float3 rgbA = (1.0/2.0)*(
        args.texture.sample(sampler,pos+dir*(1.0/3.0-0.5)).xyz
       +args.texture.sample(sampler,pos+dir*(2.0/3.0-0.5)).xyz);
    
    float3 rgbB = rgbA * (1.0/2.0)+(1.0/4.0)*(
        args.texture.sample(sampler,pos+dir*(0.0/3.0-0.5)).xyz
       +args.texture.sample(sampler,pos+dir*(3.0/3.0-0.5)).xyz);
    
    float lumaB = dot(rgbB,luma);
    
    float4 color;
    if((lumaB<lumaMin)||(lumaB>lumaMax)){
        color = float4(rgbA,1.0);
    } 
    else {
        color = float4(rgbB,1.0);
    }
    return color;
}
