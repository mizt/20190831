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

vec4 osc(vec2 _st,float time,float freq, float sync, float offset){
    vec2 st = _st;
    float r = sin((st.x-offset/freq+time*sync)*freq)*0.5  + 0.5;
    float g = sin((st.x+time*sync)*freq)*0.5 + 0.5;
    float b = sin((st.x+offset/freq+time*sync)*freq)*0.5  + 0.5;
    return vec4(r, g, b, 1.0);
}

vec4 posterize(vec4 c, float bins=3.0, float gamma=0.6){
            vec4 c2 = pow(c, vec4(gamma));
            c2 *= vec4(bins);
            c2 = floor(c2);
            c2/= vec4(bins);
            c2 = pow(c2, vec4(1.0/gamma));
            return vec4(c2.xyz, c.a);
        }
        
//https://www.youtube.com/watch?v=FpOEtm9aX0M
        vec4 color(vec4 c0, float _r=1.0, float _g=1.0, float _b=1.0, float _a=1.0){
                    vec4 c = vec4(_r, _g, _b, _a);
                    vec4 pos = step(0.0, c); // detect whether negative

                    // if > 0, return r * c0
                    // if < 0 return (1.0-r) * c0
                    return vec4(mix((1.0-c0)*abs(c), c*c0, pos));
                }


                                    vec2 rotate(vec2 st,float _time, float _angle, float speed){
                                                                vec2 xy = st - vec2(0.5);
                                                                float angle = _angle + speed *_time;
                                                                xy = mat2(cos(angle),-sin(angle), sin(angle),cos(angle))*xy;
                                                                xy += 0.5;
                                                                return xy;
                                                        }
                                                        
 fragment float4 fragmentShader(VertInOut inFrag[[stage_in]],constant FragmentShaderArguments &args[[buffer(0)]]) {
    
    //float2 st = inFrag.texcoord;
    float time = args.time[0];
    
    
  
    
    return 
    color(
        osc(rotate(inFrag.texcoord,time,0,-0.08),time,107,0,0.7),
        1,
        0,
        1
    );
}