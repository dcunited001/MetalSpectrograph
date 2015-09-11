//
//  Objects.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

struct ColorVertex {
    var vertex: float4;
    var color: float4;
}

//protocol Node<T> {
//    var name: String { get }
//    var vCount: Int { get set }
//    var vBytes: Int { get set }
//    var vBuffer: MTLBuffer { get set }
//    var device: MTLDevice { get set }
//    
//    init(name: String, vertices: Array<T>, device: MTLDevice)
//    func setVertexBuffer(vertices: Array<T>)
//}

class Node<T> {
    let name: String
    var vCount: Int
    var vBytes: Int
    var vBuffer: MTLBuffer
    var device: MTLDevice
    
    init(name: String, vertices: Array<T>, device: MTLDevice) {
        self.name = name
        self.device = device
        
        // gee, i would like to refactor this to the following method, but i guess i'm not allowed to bc swift
        // setVertexBuffer(vertices)
        self.vCount = vertices.count
        self.vBytes = Node.calculateBytes(vertices.count)
        self.vBuffer = self.device.newBufferWithBytes(vertices, length: vBytes, options: .CPUCacheModeDefaultCache)
    }
    
    func setVertexBuffer(vertices: Array<T>) {
        let vertexCount = vertices.count
        let vertexBytes = Node.calculateBytes(vertexCount)
        self.vBuffer = self.device.newBufferWithBytes(vertices, length: vertexBytes, options: .CPUCacheModeDefaultCache)
    }
    
    class func calculateBytes(vertexCount: Int) -> Int {
        return vertexCount * sizeof(T)
    }
}