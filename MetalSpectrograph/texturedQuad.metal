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
struct Uniforms {
    float4x4 modelMatrix;
};

struct Projection {
    float4x4 projectionMatrix;
};

vertex TexturedQuadVertexInOut texturedQuadVertex(constant TexturedQuadVertexInOut* vertex_array [[ buffer(0) ]],
                                      const device Uniforms& uniforms [[ buffer(1) ]],
                                      const device Projection& projection [[ buffer(2) ]],
                                      const device Uniforms& worldUniforms [[ buffer(3) ]],
                                      uint                     vid         [[ vertex_id ]])
{
    TexturedQuadVertexInOut outVertices;
    
    outVertices.m_Position = projection.projectionMatrix *
        worldUniforms.modelMatrix *
        uniforms.modelMatrix *
        vertex_array[vid].m_Position;
    outVertices.m_TexCoord = vertex_array[vid].m_TexCoord;
    
    return outVertices;
}

fragment float4 texturedQuadFragment(TexturedQuadVertexInOut     inFrag    [[ stage_in ]],
                                    texture2d<float>  tex2D     [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    float4 color = tex2D.sample(quad_sampler, float2(inFrag.m_TexCoord.x, inFrag.m_TexCoord.y));
    
    return color;
}
