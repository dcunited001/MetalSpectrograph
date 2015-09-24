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

protocol Chunkable {
    static func chunkSize() -> Int
    func toChunks() -> [float4]
    init(chunks: [float4]) // just chunking with float4 for now
}

//protocol Vertexable {
//    var position: float4 { get set }
//}

//protocol Texturable {
//    var textureCoords: float4 { get set }
//}

protocol Rotatable: Modelable {
    var rotationRate: Float { get set }
    func rotateForTime(t: CFTimeInterval, block: (Rotatable -> Float)?)
    
    var updateRotationalVectorRate: Float { get set }
    func updateRotationalVectorForTime(t: CFTimeInterval, block: (Rotatable -> float4)?)
}

extension Rotatable {
    func rotateForTime(t: CFTimeInterval, block: (Rotatable -> Float)?) {
        // TODO: clean this up.  add applyRotation? as default extension to protocol?
        // - or set up 3D transforms as a protocol?
        let rotation = (rotationRate * Float(t)) * (block?(self) ?? 1)
        self.modelRotation.w += rotation
    }
    

    func updateRotationalVectorForTime(t: CFTimeInterval, block: (Rotatable -> float4)?) {
        let rVector = (rotationRate * Float(t)) * (block?(self) ?? float4(1.0, 1.0, 1.0, 0.0))
        self.modelRotation += rVector
    }
}

protocol Translatable: Modelable {
    var translationRate: Float { get set }
    func translateForTime(t: CFTimeInterval, block: (Translatable -> float4)?)
}

extension Translatable {
    func translateForTime(t: CFTimeInterval, block: (Translatable -> float4)?) {
        let translation = (translationRate * Float(t)) * (block?(self) ?? float4(0.0, 0.0, 0.0, 0.0))
        self.modelPosition += translation
    }
}

protocol Scalable: Modelable {
    var scaleRate: Float { get set }
    func scaleForTime(t: CFTimeInterval, block: (Scalable -> float4)?)
}

extension Scalable {
    func scaleForTime(t: CFTimeInterval, block: (Scalable -> float4)?) {
        let scaleAmount = (scaleRate * Float(t)) * (block?(self) ?? float4(0.0, 0.0, 0.0, 0.0))
        self.modelScale += scaleAmount
    }
}

protocol Modelable: class {
    var modelScale:float4 { get set }
    var modelPosition:float4 { get set }
    var modelRotation:float4 { get set }
    var modelMatrix:float4x4 { get set }
    
    func setModelableDefaults()
    func calcModelMatrix() -> float4x4
    func updateModelMatrix()
    func setModelUniformsFrom(model: Modelable)
}

extension Modelable {
    func setModelableDefaults() {
        modelPosition = float4(1.0, 1.0, 1.0, 1.0)
        modelScale = float4(1.0, 1.0, 1.0, 1.0)
        modelRotation = float4(1.0, 1.0, 1.0, 90.0)
    }
    
    func calcModelMatrix() -> float4x4 {
        // scale, then rotate, then translate!!
        // - but it looks cooler identity * translate, rotate, scale
        return Metal3DTransforms.translate(modelPosition) *
            Metal3DTransforms.rotate(modelRotation) *
            Metal3DTransforms.scale(modelScale) // <== N.B. this scales first!!
    }
    
    func updateModelMatrix() {
        modelMatrix = calcModelMatrix()
    }
    
    func setModelUniformsFrom(model: Modelable) {
        modelPosition = model.modelPosition
        modelRotation = model.modelRotation
        modelScale = model.modelScale
        updateModelMatrix()
    }
}

// contains info about the world matrix
protocol Uniformable: class {
    //TODO: memoize uniformable matrix?
    var uniformScale:float4 { get set }
    var uniformPosition:float4 { get set }
    var uniformRotation:float4 { get set }
    
    //TODO: further split out MVP into separate protocol?
    var mvpMatrix:float4x4 { get set }
    var mvpBufferId:Int { get set }
    var mvpBuffer:MTLBuffer? { get set }
    var mvpPointer: UnsafeMutablePointer<Void>? { get set }
    
    func setUniformableDefaults()
    func calcUniformMatrix() -> float4x4
    func calcMvpMatrix(modelMatrix: float4x4) -> float4x4
    func updateMvpMatrix(modelMatrix: float4x4)
    func prepareMvpBuffer(device: MTLDevice)
    func prepareMvpPointer()
    func updateMvpBuffer()
}

//must deinit resources
extension Uniformable {
    func setUniformableDefaults() {
        uniformScale = float4(1.0, 1.0, 1.0, 1.0) // provides more range to place objects in world
        uniformPosition = float4(0.0, 0.0, 1.0, 1.0)
        uniformRotation = float4(1.0, 1.0, 1.0, 90)
    }
    
    func calcUniformMatrix() -> float4x4 {
        // scale, then rotate, then translate!!
        // - but it looks cooler identity * translate, rotate, scale
        return Metal3DTransforms.translate(uniformPosition) *
            Metal3DTransforms.rotate(uniformRotation) *
            Metal3DTransforms.scale(uniformScale) // <== N.B. this scales first!!
    }
    
    func updateMvpMatrix(modelMatrix: float4x4) {
        self.mvpMatrix = calcMvpMatrix(modelMatrix)
    }
    
    func prepareMvpPointer() {
        self.mvpPointer = mvpBuffer!.contents()
    }
    func prepareMvpBuffer(device: MTLDevice) {
        self.mvpBuffer = device.newBufferWithLength(sizeof(float4x4), options: .CPUCacheModeDefaultCache)
        self.mvpBuffer?.label = "MVP Buffer"
    }
    
    func updateMvpBuffer() {
        memcpy(mvpPointer!, &self.mvpMatrix, sizeof(float4x4))
    }
}

//TODO: rename (this is the view matrix, perspectable is the projectable matrix)
protocol Projectable: class {
    //TODO: memoize projectable matrix?
    var projectionEye:float3 { get set }
    var projectionCenter:float3 { get set }
    var projectionUp:float3 { get set }
    
    func setProjectableDefaults()
    func calcProjectionMatrix() -> float4x4
}

// must deinit resources
extension Projectable {
    func setProjectableDefaults() {
        projectionEye = [0.0, 0.0, 0.0]
        projectionCenter = [0.0, 0.0, 1.0]
        projectionUp = [0.0, 1.0, 0.0]
    }
    
    func calcProjectionMatrix() -> float4x4 {
        return Metal3DTransforms.lookAt(projectionEye, center: projectionCenter, up: projectionUp)
    }
}

protocol Perspectable: class {
    var perspectiveFov:Float { get set }
    var perspectiveAngle:Float { get set } // view orientation to user in degrees =) 3d
    var perspectiveAspect:Float { get set } // update when view bounds change
    var perspectiveNear:Float { get set }
    var perspectiveFar:Float { get set }
    
    func setPerspectiveDefaults()
    func calcPerspectiveMatrix() -> float4x4
}

extension Perspectable {
    func setPerspectiveDefaults() {
        perspectiveFov = 65.0
        perspectiveAngle = 35.0 // 35.0 for landscape
        perspectiveAspect = 1
        perspectiveNear = 0.01
        perspectiveFar = 100.0
    }
    
    func calcPerspectiveMatrix() -> float4x4 {
        let rAngle = Metal3DTransforms.toRadians(perspectiveAngle)
        let length = perspectiveNear * tan(rAngle)
        
        let right = length / perspectiveAspect
        let left = -right
        let top = length
        let bottom = -top
        
        return Metal3DTransforms.perspectiveFov(perspectiveAngle, aspect: perspectiveAspect, near: perspectiveNear, far: perspectiveFar)
        
        // alternate perspective using frustum_oc
        //        return Metal3DTransforms.frustum_oc(left, right: right, bottom: bottom, top: top, near: perspectiveNear, far: perspectiveFar)
    }
}