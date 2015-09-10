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
import MetalKit

// TODO: merge MetalRenderer & MetalView(MTKView)
// - to generalize rendering multiple objects

//TODO: implement AAPLViewDelegate
//TODO: overriding NSObject prevents required field initialization 
//  - in super.init, device,etc... must be initialized
class MetalRenderer {
    
    struct UIInterfaceOrientation {
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
    
    var mDevice:MTLDevice?
    
    var inflightSemaphore: dispatch_semaphore_t
    var mConstantDataBufferIndex: Int
    // this value will cycle from 0 to kInFlightCommandBuffers whenever a display completes ensuring renderer clients
    // can synchronize between kInFlightCommandBuffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    
    init() {
        mConstantDataBufferIndex = 0
        inflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers)
    }
    
    func configure(view: MTKView) {
        
        
    }
    
    func preparePipelineState(view: MTKView) -> Bool {
        
        
        return true
    }
    
    func prepareDepthStencilState() -> Bool {
        
        return true
    }
    
    func prepareTexturedQuad(texStr: NSString, extStr: NSString) -> Bool {
        
        return true
    }
    
    func prepareTransformBuffer() -> Bool {
        
        return true
    }
    
    func prepareTransforms() {
        // create a viewing matrix derived from
        // - eye point, a reference point indicating center of the scene
        // - and an up vector
        
        

    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
    func render(view: MTKView) {
        
    }
    
    func reshape(view: MTKView) {
        
    }
}