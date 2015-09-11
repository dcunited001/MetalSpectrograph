//
//  Shaders.metal
//  MetalSpectrograph
//
//  Created by David Conner on 9/8/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BasicTriangleVertexIn {
    float4 position;
    float4 color;
};

struct BasicTriangleVertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex BasicTriangleVertexOut basic_triangle_vertex(
    const device BasicTriangleVertexIn* vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]) {
    
    BasicTriangleVertexIn vIn = vertex_array[vid];
    BasicTriangleVertexOut vOut;
    vOut.position = vIn.position;
    vOut.color = vIn.color;
    
    return vOut;
}

fragment half4 basic_triangle_fragment(BasicTriangleVertexOut interpolated [[ stage_in ]]) {
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}
