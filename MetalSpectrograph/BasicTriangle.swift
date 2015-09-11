//
//  BasicTriangle.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

struct BasicTriangleVertex {
    var vertex: float4;
    var color: float4;
}

class BasicTriangle {
    
    var vertexBuffer: MTLBuffer!
    var vertexIndex:Int = 0
    struct Vertices {
        static let cnt = 3
        static let sz = cnt * (sizeof(float4) + sizeof(float4))
        static let verts: [BasicTriangleVertex] = [
            BasicTriangleVertex(vertex: float4( 0.0,  1.0, 0.0, 1.0), color: float4(1.0, 0.0, 0.0, 0.0)),
            BasicTriangleVertex(vertex: float4(-1.0, -1.0, 0.0, 1.0), color: float4(1.0, 1.0, 0.0, 0.0)),
            BasicTriangleVertex(vertex: float4( 1.0, -1.0, 0.0, 1.0), color: float4(0.0, 0.0, 1.0, 0.0))]
    }
    
    init?(device: MTLDevice) {
        
        vertexBuffer = device.newBufferWithBytes(Vertices.verts, length: Vertices.sz, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        vertexBuffer.label = "triangle vertices"
        
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: vertexIndex)
    }
}