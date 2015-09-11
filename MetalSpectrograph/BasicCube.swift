//
//  BasicCube.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

// TODO: how to dynamically swap out vertex colors?
// TODO: how to make truly generic?
class Cube: Node<ColorVertex> {
    
    class func cubeVertices() -> [ColorVertex] {
        return [
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4(-1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4(-1.0, -1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            ColorVertex(vertex: float4( 1.0,  1.0,  1.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0))
        ]
    }
    
    class func cubeVerticesArray(A: ColorVertex) -> [ColorVertex] {
        
    }
    
    init(devices: MTLDevice) {
        let vertices = Cube.constructCube()
        super.init(name: "Cube", vertices: )
    }
}
