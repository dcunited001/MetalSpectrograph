//
//  Node.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/24/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Metal
import simd

protocol RenderEncodable {
    func encode(renderEncoder: MTLRenderCommandEncoder)
}

// TODO: for cube (and other polygons),
// - determine indexing functions for textures
// TODO: multi-perspective renderer
//
//protocol VertexBufferable {
//    var vCount:Int { get set }
//    var vBytes:Int { get set }
//    var vertexBufferId:Int { get set }
//    var vertexBuffer:MTLBuffer { get set }
//    var device:MTLDevice { get set }
//    
//    func getVertexSize() -> Int
//    static func getVertexSize() -> Int
//    func getRawVertices() -> [protocol<Vertexable, Chunkable>]
//    func setVertexBuffer(vertices: [Vertexable])
//    static func calculateBytes(vertexCount: Int) -> Int
//}

//TODO: evaluate new vertexable/colorable/textureable protocols
// - do i really need to differentiate these?

protocol SpectraNodeVertexable {
    var vertexBuffer: SpectraBuffer? { get set }
}

protocol SpectraNodeColorable {
    var colorBuffer: SpectraBuffer? { get set }
}

protocol SpectraNodeTextureable {
    var textureBuffer: SpectraBuffer { get set }
}

class SpectraNode: Modelable {
    var vertexBuffer: SpectraBuffer?
    var buffers: [SpectraMetalBuffer] = []
    
    var device:MTLDevice
    
    // Modelable
    var modelScale = float4(1.0, 1.0, 1.0, 1.0)
    var modelPosition = float4(0.0, 0.0, 0.0, 1.0)
    var modelRotation = float4(1.0, 1.0, 1.0, 90)
    var modelMatrix: float4x4 = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
    
    // TODO: reorder params
    init(name: String, vertices: [float4], device: MTLDevice) {
        self.name = name
        self.device = device
        
        self.vCount = vertices.count
        self.vBytes = Node<T>.calculateBytes(vCount)
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vBytes, options: .CPUCacheModeDefaultCache)
        self.vertexBuffer.label = "\(T.self) vertices"
        updateModelMatrix()
    }
    
    func getRawVertices() -> [protocol<Vertexable, Chunkable>] {
        return []
    }
    
    func getVertexSize() -> Int {
        return sizeof(T)
    }
    
    static func getVertexSize() -> Int {
        return sizeof(T)
    }
    
    static func calculateBytes(vertexCount: Int) -> Int {
        return vertexCount * sizeof(T)
    }
}