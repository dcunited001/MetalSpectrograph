//
//  TexturedQuadRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

// TODO: abstract textured quad behavior from image-loaded texture behavior
class TexturedQuadImgRenderer: MetalRenderer, MetalViewDelegate {
    
    var pipelineState: MTLRenderPipelineState?
    var inTexture: ImageTexture?
    var size: CGSize = CGSize()
    var quad: TexturedQuad?
    var transformBuffer: MTLBuffer?
    var lookAtMatrix: float4x4?
    var translateMatrix: float4x4?
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        guard preparePipelineState(view) else {
            print("Failed creating a compiled pipeline state object!")
            return
        }
        
        //TODO: add asset?
        guard prepareTexturedQuad("Default", extStr: "jpg") else {
            print("Failed creating a textured quad!")
            return
        }
        
        guard prepareDepthStencilState() else {
            print("Failed creating a depth stencil state!")
            return
        }
        
        guard prepareTransformBuffer() else {
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
        quadPipelineStateDescriptor.stencilAttachmentPixelFormat = view.stencilPixelFormat!
        quadPipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        quadPipelineStateDescriptor.sampleCount = view.sampleCount
        quadPipelineStateDescriptor.vertexFunction = vertexProgram
        quadPipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        do {
            try pipelineState = (device!.newRenderPipelineStateWithDescriptor(quadPipelineStateDescriptor))
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
        guard let newTexture = ImageTexture.init(name: texStr as String, ext: extStr as String) else {
            print("Failed to create ImageTexture")
            return false
        }
        inTexture = newTexture
        inTexture!.texture?.label = texStr as String
        
        guard inTexture!.finalize(device!) else {
            print("Failed to finalize ImageTexture")
            return false
        }
        
        size.width = CGFloat(inTexture!.width)
        size.height = CGFloat(inTexture!.height)
        
        guard let newQuad = TexturedQuad(device: device!) else {
            print("Failed to create TexturedQuad")
            return false
        }
        quad = newQuad
        quad!.size = size
        
        return true
    }
    
    func prepareTransformBuffer() -> Bool {
        guard let newTransformBuffer = device?.newBufferWithLength(kSzBufferLimitsPerFrame, options: .CPUCacheModeDefaultCache) else {
            print("Failed to create transform buffer")
            return false
        }
        transformBuffer = newTransformBuffer
        transformBuffer!.label = "TransformBuffer"
        return true
    }
    
    func prepareTransforms() {
        // create a viewing matrix derived from
        // - eye point, a reference point indicating center of the scene
        // - and an up vector
        
        let eye:float3 = [0.0, 0.0, 0.0]
        let center:float3 = [0.0, 0.0, 1.0]
        let up:float3 = [0.0, 1.0, 0.0]
        
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