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

// TODO: genericize views?   MetalView<BasicTriangle>   ... hmmmmm, maybe
// TODO: genericize renderers?   MetalRenderer<BasicTriangle>

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

//protocol Uniformable?

protocol Rotatable {
    var rotationRate: Float { get set }
    func rotateForTime(t: CFTimeInterval, block: (Rotatable -> Float)?)
    
    var updateRotationalVectorRate: Float { get set }
    func updateRotationalVectorForTime(t: CFTimeInterval, block: (Rotatable -> float4)?)
}

protocol Translatable {
    var translationRate: Float { get set }
    func translateForTime(t: CFTimeInterval, block: (Translatable -> float4)?)
}

protocol Scalable {
    var scaleRate: Float { get set }
    func scaleForTime(t: CFTimeInterval, block: (Scalable -> float4)?)
}

// nullify alphas and treat colors as though they are coordinate system.
//   mod to correct?  or div by max.
//   for now, just using the uniform
protocol VertexColorModulatable {
    var changeRate: Float { get set }
    func translateForTime(t: CFTimeInterval, block: (Scalable -> float4)?)
}

//TODO: refactor uniformable
protocol Uniformable: class {
    var modelScale:float4 { get set }
    var modelPosition:float4 { get set }
    var modelRotation:float4 { get set }
    var modelMatrix:float4x4 { get set }
    var uniformBufferId:Int { get set }
    var uniformBuffer:MTLBuffer? { get set }
    var modelPointer: UnsafeMutablePointer<Void>? { get set }
}

//must deinit resources
extension Uniformable {
    func calcModelMatrix() -> float4x4 {
        return float4x4(diagonal: float4(1.0,1.0,1.0,1.0)) *
            Metal3DTransforms.translate(modelPosition) *
            Metal3DTransforms.rotate(modelRotation) *
            Metal3DTransforms.scale(modelScale)
    }
    
    func initModelMatrix() {
        self.modelMatrix = calcModelMatrix()
        self.modelPointer = uniformBuffer!.contents()
    }
    
    func prepareUniformBuffer(device: MTLDevice) {
        self.uniformBuffer = device.newBufferWithLength(sizeof(float4x4), options: .CPUCacheModeDefaultCache)
    }
    
    func updateUniformBuffer() {
        memcpy(modelPointer!, &self.modelMatrix, sizeof(float4x4))
    }

}

protocol Projectable: class {
    var projectionEye:float3 { get set }
    var projectionCenter:float3 { get set }
    var projectionUp:float3 { get set }
    var projectionMatrix:float4x4 { get set }
    var projectionBuffer:MTLBuffer? { get set }
    var projectionPointer: UnsafeMutablePointer<Void>? { get set }
    func calcProjectionMatrix() -> float4x4
    func prepareProjectionBuffer(device: MTLDevice)
    func updateProjectionBuffer()
}

// must deinit resources
extension Projectable {
    func calcProjectionMatrix() -> float4x4 {
        return Metal3DTransforms.lookAt(projectionEye, center: projectionCenter, up: projectionUp)
    }
    func prepareProjectionBuffer(device: MTLDevice) {
        self.projectionBuffer = device.newBufferWithLength(sizeof(float4x4), options: .CPUCacheModeDefaultCache)
        self.projectionBuffer?.label = "projection buffer"
        self.projectionPointer = projectionBuffer?.contents()
    }
    func updateProjectionBuffer() {
        memcpy(self.projectionPointer!, &self.projectionMatrix, sizeof(float4x4))
    }
}

// TODO: for cube (and other polygons),
// - determine indexing functions for textures
// TODO: multi-persective renderer

class Node<T: Vertexable>: Uniformable {
    let name:String
    var vCount:Int
    var vBytes:Int
    let vertexBufferId:Int = 0
    var vertexBuffer:MTLBuffer
    var device:MTLDevice
    
    // Uniformable
    var uniformBuffer:MTLBuffer?
    var uniformBufferId:Int = 0
    var modelScale = float4(1.0, 1.0, 1.0, 1.0)
    var modelPosition = float4(0.0, 0.0, 0.0, 1.0)
    var modelRotation = float4(1.0, 1.0, 1.0, 90)
    var modelMatrix: float4x4 = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
    var modelPointer: UnsafeMutablePointer<Void>?
    
    
    init(name: String, vertices: [T], device: MTLDevice) {
        self.name = name
        self.device = device
        
        // setVertexBuffer(vertices)
        self.vCount = vertices.count
        self.vBytes = Node<T>.calculateBytes(vCount)
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vBytes, options: .CPUCacheModeDefaultCache)
        
        self.uniformBuffer = self.device.newBufferWithLength(sizeof(float4x4), options: .CPUCacheModeDefaultCache)
        
        self.modelMatrix = calcModelMatrix()
        self.modelPointer = uniformBuffer!.contents()
        updateUniformBuffer()
    }
    
    func setVertexBuffer(vertices: [Vertexable]) {
        let vertexCount = vertices.count
        let vertexBytes = Node<T>.calculateBytes(vCount)
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vertexBytes, options: .CPUCacheModeDefaultCache)
        self.vertexBuffer.label = "\(T.self) vertices"
    }
    
    static func calculateBytes(vertexCount: Int) -> Int {
        return vertexCount * sizeof(T)
    }
}