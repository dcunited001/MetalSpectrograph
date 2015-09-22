/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Textured quad shader.
 */

#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

using namespace metal;

struct TexturedQuadVertexInOut
{
    float4 m_Position [[position]];
    float4 m_TexCoord [[user(texturecoord)]];
};

// TODO: add uniforms/projection and other data types to shared metal file
struct UniformsMVP {
    float4x4 modelMatrix;
};

struct Projection {
    float4x4 projectionMatrix;
};

vertex TexturedQuadVertexInOut texQuadVertex(constant TexturedQuadVertexInOut* vertex_array [[ buffer(0) ]],
                                      const device UniformsMVP& mvp [[ buffer(1) ]],
                                      uint                     vid         [[ vertex_id ]])
{
    TexturedQuadVertexInOut outVertices;
    
    outVertices.m_Position = mvp.modelMatrix * vertex_array[vid].m_Position;
    outVertices.m_TexCoord = vertex_array[vid].m_TexCoord;
    
    return outVertices;
}

fragment float4 texQuadFragment(TexturedQuadVertexInOut     inFrag    [[ stage_in ]],
                                    texture2d<float>  tex2D     [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    float4 color = tex2D.sample(quad_sampler, float2(inFrag.m_TexCoord.x, inFrag.m_TexCoord.y));
    
    return color;
}

fragment float4 texQuadFragmentColorShift(TexturedQuadVertexInOut     inFrag    [[ stage_in ]],
                                          texture2d<float>  tex2D     [[ texture(0) ]],
                                          constant float &colorShift [[ buffer(0) ]])
{
    constexpr sampler quad_sampler;
    float4 color = tex2D.sample(quad_sampler, float2(inFrag.m_TexCoord.x, inFrag.m_TexCoord.y));
    
    int quanta = 255*255*255;
    float fQuanta = float(quanta);
    
    //TODO: instead try with periodic functions
    // - also, are high values of color x,y,z limiting the range?
    color = float4((int((color.x + colorShift) * quanta) % quanta) / fQuanta,
                   (int((color.y + colorShift) * quanta) % quanta) / fQuanta,
                   (int((color.z + colorShift) * quanta) % quanta) / fQuanta,
                   1.0);
    
    return color;
}

//kernel void rainbowNoise(texture2d<float, access::write> outTexture [[texture(0)]]
//                         uint id [[ thread_position_in_grid ]]) {
//    //TODO: figure out how use random numbers in the shader file
////    float4 color = float(rand()) / RAND_MAX;
////    outTexture.write(
//}
