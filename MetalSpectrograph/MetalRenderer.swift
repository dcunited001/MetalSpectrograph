//
//  MetalRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

/*
Mostly copied from Apple's AAPLRenderer.mm

Metal Renderer for Metal Basic 3D. Acts as the update and render delegate for the view controller and performs rendering. In MetalBasic3D, the renderer draws N cubes, whos color values change every update.
*/

import simd
import Cocoa
import MetalKit

// TODO: merge MetalRenderer & MetalView(MTKView)
// - to generalize rendering multiple objects

//TODO: implement AAPLViewDelegate
//TODO: overriding NSObject prevents required field initialization 
//  - in super.init, device,etc... must be initialized
class MetalRenderer {
    
    // TODO: remove on OSX
    struct MetalInterfaceOrientation {
        var LandscapeAngle:Float = 35.0
        var PortraitAngle:Float = 50.0
    }
    
    struct Perspective {
        var Near:Float = 0.1
        var Far:Float = 100.0
    }
    
    let kSzSIMDFloat4x4 = sizeof(float4x4)
    let kSzBufferLimitsPerFrame = sizeof(float4x4)
    let kInFlightCommandBuffers = 3
    
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var shaderLibrary: MTLLibrary?
    var depthState: MTLDepthStencilState?
    
    var inflightSemaphore: dispatch_semaphore_t
    var mConstantDataBufferIndex: Int
    // this value will cycle from 0 to kInFlightCommandBuffers whenever a display completes ensuring renderer clients
    // can synchronize between kInFlightCommandBuffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    
    init() {
        mConstantDataBufferIndex = 0
        inflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers)
    }
    
    func configure(view: MetalView) {
        view.depthPixelFormat = .Depth32Float
        view.colorPixelFormat = MTLPixelFormat.BGRA8Unorm // ?? correct
        view.stencilPixelFormat = MTLPixelFormat.Invalid
        view.sampleCount = 1
        
        guard let viewDevice = view.device else {
            print("Failed retrieving device from view")
            return
        }
        
        device = viewDevice
        commandQueue = device!.newCommandQueue()
        shaderLibrary = device!.newDefaultLibrary()
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        
    }
}

protocol Renderable {
    var pipelineState: MTLRenderPipelineState? { get set }
    func configure(view: MetalView)
    func preparePipelineState(view: MetalView) -> Bool
    func prepareObject() -> Bool
    func prepareDepthStencilState() -> Bool
    func prepareTransformBuffer() -> Bool
    func prepareTransforms() -> Bool
    func encode(renderEncoder: MTLRenderCommandEncoder)
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    // updateLogic here?
}

class CollectionRenderer<T>: MetalRenderer, Renderable {
    var pipelineState: MTLRenderPipelineState?
    override func configure(view: MetalView){
        super.configure(view)
    }
    func preparePipelineState(view: MetalView) -> Bool {
        return false
    }
    func prepareObject() -> Bool {
        return false
    }
    func prepareDepthStencilState() -> Bool {
        return false
    }
    func prepareTransformBuffer() -> Bool {
        return false
    }
    func prepareTransforms() -> Bool {
        return false
    }
    override func encode(renderEncoder: MTLRenderCommandEncoder) {
        super.encode(renderEncoder)
    }
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
    }
}
