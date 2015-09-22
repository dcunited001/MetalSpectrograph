//
//  Lattice.metal
//  MetalSpectrograph
//
//  Created by David Conner on 9/22/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// TODO: destructure position and color for input
// - send in only float4* for position and float4* for color
// - then zip them together for input to fragment shader

struct LatticeColorVertexInOut {
    float4 position [[ position ]];
    float4 color;
};

struct LatticeTextureVertexInOut {
    float4 position [[ position ]];
    float4 texCoord [[ user(texturecoord) ]];
};

vertex LatticeTextureVertexInOut audioLatticeCircularWave
(
 constant LatticeTextureVertexInOut* vin [[ buffer(0) ]],
 const device float4* waveformBuffer [[ buffer(1) ]],
 const device float4 &center [[ buffer(2) ]],
 uint vid [[ vertex_id ]])
{
    LatticeTextureVertexInOut vout = vin[vid];
    
    // given vid, translate to lattice row/col
    // - and then translate to waveform buffer space
    // - identify waveform buffer coordinates to interpolate
    // - modify position and return
    
    return vout;
}

vertex LatticeTextureVertexInOut audioLatticeLongitudinalWave
(
 constant LatticeTextureVertexInOut* vin [[buffer(0) ]],
 const device float4* waveformBuffer [[ buffer(1) ]],
 uint vid [[ vertex_id ]])
{
    LatticeTextureVertexInOut vout = vin[vid];
    
    return vout;
}

// - analagous vertex shader for fragment shader below
//vertex LatticeTextureVertexInOut audioLatticeModulateDistance
//fragment float4 colorShiftByDistance

fragment float4 textureShiftByDistance
(
  LatticeTextureVertexInOut fragIn [[ stage_in ]],
  texture2d<float> tex [[ texture(0) ]],
  const device float4 &vanishingPoint [[ buffer(1) ]])
{
     //adjust magnitude of colorshift with sigmoid function?
    
    constexpr sampler quad_sampler;
    float4 color = tex.sample(quad_sampler, float2(fragIn.texCoord.x, fragIn.texCoord.y));
    
    return color;
}


