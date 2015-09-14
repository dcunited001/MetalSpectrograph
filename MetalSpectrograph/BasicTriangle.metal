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

struct Uniforms {
    float4x4 modelMatrix;
};

struct Projection {
    float4x4 projectionMatrix;
};


vertex BasicTriangleVertexOut basic_triangle_vertex
(
 const device BasicTriangleVertexIn* vertex_array [[ buffer(0) ]],
 const device Uniforms& uniforms [[ buffer(1) ]],
 const device Projection& projection [[ buffer(2) ]],
 const device Uniforms& worldUniforms [[ buffer(3) ]],
    unsigned int vid [[ vertex_id ]])
{
    BasicTriangleVertexIn vIn = vertex_array[vid];
    BasicTriangleVertexOut vOut;
    vOut.position = projection.projectionMatrix *
        worldUniforms.modelMatrix *
        uniforms.modelMatrix *
        vIn.position;
    vOut.color = vIn.color;
    
    return vOut;
}

fragment half4 basic_triangle_fragment
(
    BasicTriangleVertexOut interpolated [[ stage_in ]])
{
    return half4(interpolated.color[0], interpolated.color[1], interpolated.color[2], interpolated.color[3]);
}

// reuses the uniforms matrix to shift color as though it's a coordinate system
vertex BasicTriangleVertexOut uniform_color_morph_triangle_vertex
(
 const device BasicTriangleVertexIn* vertex_array [[ buffer(0) ]],
 const device Uniforms& uniforms [[ buffer(1) ]],
 const device Projection& projection [[ buffer(2) ]],
 const device Uniforms& worldUniforms [[ buffer(3) ]],
 unsigned int vid [[ vertex_id ]])
{
    int quanta = 8;
    float fQuanta = float(quanta);
    
    BasicTriangleVertexIn vIn = vertex_array[vid];
    BasicTriangleVertexOut vOut;
    vOut.position = projection.projectionMatrix * worldUniforms.modelMatrix * uniforms.modelMatrix * vIn.position;
    float4 colorOut = uniforms.modelMatrix * float4(vIn.color.x, vIn.color.y, vIn.color.z, 1.0);
    vOut.color = float4(int(colorOut.x * quanta)/fQuanta,
                        int(colorOut.y * quanta)/fQuanta,
                        int(colorOut.z * quanta)/fQuanta,
                        vIn.color.w);
    
    return vOut;
}
// reuses the uniforms matrix to shift color as though it's a coordinate system
vertex BasicTriangleVertexOut continuous_uniform_color_morph_triangle_vertex
(
 const device BasicTriangleVertexIn* vertex_array [[ buffer(0) ]],
 const device Uniforms& uniforms [[ buffer(1) ]],
 const device Projection& projection [[ buffer(2) ]],
 const device Uniforms& worldUniforms [[ buffer(3) ]],
 unsigned int vid [[ vertex_id ]])
{
    BasicTriangleVertexIn vIn = vertex_array[vid];
    BasicTriangleVertexOut vOut;
    vOut.position = projection.projectionMatrix * worldUniforms.modelMatrix * uniforms.modelMatrix * vIn.position;
    float4 colorOut = uniforms.modelMatrix * float4(vIn.color.x, vIn.color.y, vIn.color.z, 1.0);
    vOut.color = float4(colorOut.x,
                        colorOut.y,
                        colorOut.z,
                        vIn.color.w);
    
    return vOut;
}
