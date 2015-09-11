//
//  Shaders.metal
//  MetalSpectrograph
//
//  Created by David Conner on 9/8/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(
    const device float4* vertex_array [[ buffer(0) ]],
    unsigned int vid [[ vertex_id ]]) {
    return vertex_array[vid];
}

fragment half4 basic_fragment() {
    // TODO: update to return other colors
    return half4(1.0);
}
