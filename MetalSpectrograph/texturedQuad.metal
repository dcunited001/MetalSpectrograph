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

struct VertexInOut
{
    float4 m_Position [[position]];
    float4 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut texturedQuadVertex(constant VertexInOut* vertex_array [[ buffer(0) ]],
                                      constant float4x4       *pMVP        [[ buffer(1) ]],
                                      uint                     vid         [[ vertex_id ]])
{
    VertexInOut outVertices;
    
    outVertices.m_Position = *pMVP * vertex_array[vid].m_Position;
    outVertices.m_TexCoord = vertex_array[vid].m_TexCoord;
    
    return outVertices;
}

fragment float4 texturedQuadFragment(VertexInOut     inFrag    [[ stage_in ]],
                                    texture2d<float>  tex2D     [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    float4 color = tex2D.sample(quad_sampler, float2(inFrag.m_TexCoord.x, inFrag.m_TexCoord.y));
    
    return color;
}
