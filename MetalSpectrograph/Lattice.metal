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
    float4 tex [[ user(texturecoord) ]];
};

struct WaveformParams {
    int stride;
    int start;
};

struct QuadLatticeConfig {
    int2 size;
};

vertex LatticeTextureVertexInOut audioLatticeCircularWave
(
 constant LatticeTextureVertexInOut* vin [[ buffer(0) ]],
 const device float4x4& mvp [[ buffer(1) ]],
 constant float* waveformBuffer [[ buffer(2) ]],
 const device WaveformParams &waveformParams [[ buffer(3) ]],
 const device QuadLatticeConfig &latticeParams [[ buffer(4) ]],
// const device float4 &center [[ buffer(5) ]],
 uint vid [[ vertex_id ]])
{
    int triangleId = vid / 3;
    int triangleIndex = triangleId % 2;
    int triangleVertex = vid % 3;
    
    int elementsPerRow = (2 * latticeParams.size.x);
    int latticeRow = triangleId / elementsPerRow;
    int latticeCol = (triangleId - latticeRow * elementsPerRow) / 2;
    
    int latticeX = latticeCol;
    int latticeY = latticeRow;
    
    // A ---- B ---- W
    // | 0   /| 2   /|
    // |   /  |   /  |
    // | /  1 | /   3|
    // D ---- C ---- X
    
    if (triangleIndex == 0) {
        if (triangleVertex == 0) {
            latticeY += 1;
        }
        if (triangleVertex == 2) {
            latticeX += 1;
        }
    } else {
        if (triangleVertex == 0) {
            latticeX += 1;
        }
        if (triangleVertex == 1) {
            latticeX += 1;
            latticeY += 1;
        }
        if (triangleVertex == 2) {
            latticeY += 1;
        }
    }
    
    int waveformIndex = waveformParams.stride * latticeY + latticeX * 10;
    float waveformZ = waveformBuffer[vid + waveformIndex];
    
    LatticeTextureVertexInOut vout = vin[vid];
    vout.position = vin[vid].position;
    vout.position.z = vout.position.z + waveformZ;
    
    // given vid, translate to lattice row/col
    // - and then translate to waveform buffer space
    // - identify waveform buffer coordinates to interpolate
    // - modify position and return
    
    vout.position = mvp * vout.position;
    vout.tex = vin[vid].tex;
    
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
    float4 color = tex.sample(quad_sampler, float2(fragIn.tex.x, fragIn.tex.y));
    
    return color;
}


