#include <metal_stdlib>
using namespace metal;

kernel void processimage(
    texture2d<float,access::sample> src[[texture(0)]],
    texture2d<float,access::write> dst[[texture(1)]],
    uint2 gid[[thread_position_in_grid]]) {
        
    dst.write(src.read(gid),gid);

}