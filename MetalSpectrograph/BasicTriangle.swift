//
//  BasicTriangle.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

class BasicTriangle {
    
    var vertexBuffer: MTLBuffer!
    var vertexIndex:Int = 0
    struct Vertices {
        static let cnt = 3
        static let sz = cnt * sizeof(float4)
        static let verts: [float4] = [
            float4(0.0, 1.0, 0.0, 1.0),
            float4(-1.0, -1.0, 0.0, 1.0),
            float4(1.0, -1.0, 0.0, 1.0)]
    }
    
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    init?(device: MTLDevice) {

        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
//        vertexBuffer = device.newBufferWithBytes(Vertices.verts, length: Vertices.sz, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        vertexBuffer.label = "triangle vertices"
        
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: vertexIndex)
    }
}