//
//  Objects.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

//https://developer.apple.com/library/prerelease/ios/samplecode/MetalKitEssentials/Introduction/Intro.html#//apple_ref/doc/uid/TP40016233-Intro-DontLinkElementID_2
// http://metalbyexample.com/introduction-to-compute/
// http://metalbyexample.com/introduction-to-compute/
// - https://github.com/FlexMonkey/MetalKit-Particles/tree/master/OSXMetalParticles

import simd
import Metal

// ugh how to convert to and from various types, using only bytes ... 
// ... 
// ... oh yeh... C & pointers!!!  Direct memory access, the O.G. Generic

protocol Vertexable {
    var vertex: float4 { get set }
    static func chunkSize() -> Int
    func toChunks() -> [float4]
    init(chunks: [float4]) // just chunking with float4 for now
}

protocol Colorable {
    var color: float4 { get set }
}

struct ColorVertex: Vertexable, Colorable {
    var vertex: float4;
    var color: float4;
    
    init(chunks: [float4]) {
        self.vertex = chunks[0]
        self.color = chunks[1]
    }
    
    init(vertex: float4, color: float4) {
        self.vertex = vertex
        self.color = color
    }
    
    func toChunks() -> [float4] {
        return [vertex, color]
    }
    
    static func chunkSize() -> Int {
        return sizeof(ColorVertex)
    }
}

class Node<T: Vertexable> {
    let name:String
    var vCount:Int
    var vBytes:Int
    var vBuffer:MTLBuffer
    var device:MTLDevice
    
    init(name: String, vertices: [T], device: MTLDevice) {
        self.name = name
        self.device = device
        
        // wish i could refactor this to the following method, but i guess i'm not allowed to bc swift
        // setVertexBuffer(vertices)
        self.vCount = vertices.count
        self.vBytes = Node<T>.calculateBytes(vCount)
        self.vBuffer = self.device.newBufferWithBytes(vertices, length: vBytes, options: .CPUCacheModeDefaultCache)
    }
    
    func setVertexBuffer(vertices: [Vertexable]) {
        let vertexCount = vertices.count
        let vertexBytes = Node<T>.calculateBytes(vCount)
        self.vBuffer = self.device.newBufferWithBytes(vertices, length: vertexBytes, options: .CPUCacheModeDefaultCache)
    }
    
    static func calculateBytes(vertexCount: Int) -> Int {
        return vertexCount * sizeof(T)
    }
}