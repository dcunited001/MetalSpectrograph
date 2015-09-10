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
        //set device
        //configure view for renderer
        
        view.depthPixelFormat = .Depth32Float
        view.colorPixelFormat = MTLPixelFormat.BGRA8Unorm // ?? correct
        view.stencilPixelFormat = MTLPixelFormat.Invalid
        view.sampleCount = 1
        
        guard let device = view.device else {
            print("Failed retrieving device from view")
            return
        }

        commandQueue = device.newCommandQueue()
        shaderLibrary = device.newDefaultLibrary()
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        
    }
}

// TODO: abstract textured quad behavior from image-loaded texture behavior
class SingleTextureRenderer: MetalRenderer, MetalViewDelegate {
    
    var pipelineState: MTLRenderPipelineState?
    var inTexture: ImageTexture?
    var size: CGSize = CGSize()
    var quad: TexturedQuad?
    var transformBuffer: MTLBuffer?
    var lookAtMatrix: float4x4?
    var translateMatrix: float4x4?
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        guard !preparePipelineState(view) else {
            print("Failed creating a compiled pipeline state object!")
            return
        }
        
        //TODO: add asset?
        guard !prepareTexturedQuad("Default", extStr: "jpg") else {
            print("Failed creating a textured quad!")
            return
        }
        
        guard !prepareDepthStencilState() else {
            print("Failed creating a depth stencil state!")
            return
        }
        
        guard !prepareDepthStencilState() else {
            print("Failed creating a depth stencil state!")
            return
        }
        
        guard !prepareTransformBuffer() else {
            print("Failed creating a transform buffer!")
            return
        }
        
        prepareTransforms()
    }
    
    func preparePipelineState(view: MetalView) -> Bool {
        guard let fragmentProgram = shaderLibrary?.newFunctionWithName("texturedQuadFragment") else {
            print("Couldn't load texturedQuadFragment")
            return false
        }
        
        guard let vertexProgram = shaderLibrary?.newFunctionWithName("texturedQuadVertex") else {
            print("Couldn't load texturedQuadVertex")
            return false
        }
        
        let quadPipelineStateDescriptor = MTLRenderPipelineDescriptor()
        quadPipelineStateDescriptor.depthAttachmentPixelFormat = view.depthPixelFormat!
        quadPipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthPixelFormat!
        quadPipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        quadPipelineStateDescriptor.sampleCount = view.sampleCount
        quadPipelineStateDescriptor.vertexFunction = vertexProgram
        quadPipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        do {
            try pipelineState = (device?.newRenderPipelineStateWithDescriptor(quadPipelineStateDescriptor))!
        } catch(let err) {
            print("Failed to create pipeline state, error: \(err)")
            return false
        }
        
        return true
    }
    
    func prepareDepthStencilState() -> Bool {
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .Always
        depthStateDesc.depthWriteEnabled = true
        depthState = device?.newDepthStencilStateWithDescriptor(depthStateDesc)
        
        return true
    }
    
    func prepareTexturedQuad(texStr: NSString, extStr: NSString) -> Bool {
        guard let inTexture = ImageTexture.init(name: texStr as String, ext: extStr as String) else {
            print("Failed to create ImageTexture")
            return false
        }
        inTexture.texture!.label = texStr as String
        
        guard (!inTexture.finalize(device!)) else {
            print("Failed to finalize ImageTexture")
            return false
        }
        
        size.width = CGFloat(inTexture.width)
        size.height = CGFloat(inTexture.height)
        
        guard let quad = TexturedQuad(device: device!) else {
            print("Failed to create TexturedQuad")
            return false
        }
        quad.size = size
        
        return true
    }

    func prepareTransformBuffer() -> Bool {
        guard let transformBuffer = device?.newBufferWithLength(kSzBufferLimitsPerFrame, options: .CPUCacheModeDefaultCache) else {
            print("Failed to create transform buffer")
            return false
        }
        
        transformBuffer.label = "TransformBuffer"
        return true
    }
    
    func prepareTransforms() {
        // create a viewing matrix derived from
        // - eye point, a reference point indicating center of the scene
        // - and an up vector
        
        var eye:float3 = [0.0, 0.0, 0.0]
        var center:float3 = [0.0, 0.0, 1.0]
        var up:float3 = [0.0, 1.0, 0.0]
        
        lookAtMatrix = Metal3DTransforms.lookAt(eye, center: center, up: up)
        translateMatrix = Metal3DTransforms.translate(0.0, y: -0.25, z: 2.0)
    }
    
    override func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("encode quad")
        renderEncoder.setFrontFacingWinding(.CounterClockwise)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setRenderPipelineState(pipelineState!)
        renderEncoder.setVertexBuffer(transformBuffer, offset: 0, atIndex: 2)
        renderEncoder.setFragmentTexture(inTexture!.texture, atIndex: 0)
        
        quad!.encode(renderEncoder)
        renderEncoder.drawPrimitives(.Triangle,
            vertexStart: 0,
            vertexCount: 6, //TODO: replace with constant?
            instanceCount: 1)
        
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    @objc func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        self.encode(renderEncoder)
        commandBuffer.presentDrawable(drawable)

        // __block??
        let dispatchSemaphore: dispatch_semaphore_t = inflightSemaphore

        commandBuffer.addCompletedHandler { (cmdBuffer) in
            dispatch_semaphore_signal(dispatchSemaphore)
        }
        commandBuffer.commit()
    }
    
    @objc func updateLogic(timeSinseLastUpdate: CFTimeInterval) {
        
        
    }
}