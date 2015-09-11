//
//  BasicTriangle.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

// TODO: refactor with Node<ColorVertex>

class BasicTriangle<T: Vertexable>: Node<T> {
    
    class func triangleVertices() -> [T] {
        return [
            T(chunks: [float4( 0.0,  1.0, 0.0, 1.0), float4(1.0, 0.0, 0.0, 0.0)]),
            T(chunks: [float4(-1.0, -1.0, 0.0, 1.0), float4(0.0, 1.0, 0.0, 0.0)]),
            T(chunks: [float4( 1.0, -1.0, 0.0, 1.0), float4(0.0, 0.0, 1.0, 0.0)])
        ]
    }
    
    init(device: MTLDevice) {
        let triangleVertices = BasicTriangle<T>.triangleVertices()
        super.init(name: "BasicTriangle", vertices: triangleVertices, device: device)
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
    }
}