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
class TexturedQuadImgRenderer: MetalRenderer, MetalViewDelegate, Projectable, Uniformable {
    
    var pipelineState: MTLRenderPipelineState?
    var inTexture: ImageTexture?
    var size: CGSize = CGSize()
    var object: TexturedQuad<TexturedVertex>?
    
    let vertexShaderName = "texturedQuadVertex"
    let fragmentShaderName = "texturedQuadFragment"
    
    //Projectable
    var projectionEye:float3 = [0.0, 0.0, 0.0]
    var projectionCenter:float3 = [0.0, 0.0, 2.0]
    var projectionUp:float3 = [0.0, 1.0, 1.0]
    var projectionMatrix:float4x4 = float4x4(diagonal: float4(1.0, 1.0, 1.0, 1.0))
    var projectionBuffer:MTLBuffer?
    var projectionPointer: UnsafeMutablePointer<Void>?
    
    // Uniformable
    var uniformBuffer:MTLBuffer?
    var uniformBufferId:Int = 1
    var modelScale = float4(1.0, 1.0, 1.0, 1.0)
    var modelPosition = float4(0.0, 0.0, 0.0, 2.0)
    var modelRotation = float4(1.0, 1.0, 1.0, 90)
    var modelMatrix: float4x4 = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
    var modelPointer: UnsafeMutablePointer<Void>?
    
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
        
        self.projectionMatrix = calcProjectionMatrix()
        prepareProjectionBuffer(device!)
        updateProjectionBuffer()
        
        prepareUniformBuffer(device!)
        initModelMatrix()
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
//        quadPipelineStateDescriptor.depthAttachmentPixelFormat = view.depthPixelFormat!
        quadPipelineStateDescriptor.depthAttachmentPixelFormat = .Invalid

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

        object = TexturedQuad<TexturedVertex>(device: device!)
        object!.size = size
        
        return true
    }
    
    override func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("encode quad")
        renderEncoder.setFrontFacingWinding(.CounterClockwise)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setRenderPipelineState(pipelineState!)
        renderEncoder.setVertexBuffer(projectionBuffer, offset: 0, atIndex: 1)
        renderEncoder.setFragmentTexture(inTexture!.texture, atIndex: 0)
        
        object!.encode(renderEncoder)
        renderEncoder.drawPrimitives(.Triangle,
            vertexStart: 0,
            vertexCount: 6, //TODO: replace with constant?
            instanceCount: 1)
        
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    @objc func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        dispatch_semaphore_wait(avaliableResourcesSemaphore, DISPATCH_TIME_FOREVER)
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        self.encode(renderEncoder)
        commandBuffer.presentDrawable(drawable)
        
        // __block??
        let dispatchSemaphore: dispatch_semaphore_t = avaliableResourcesSemaphore
        
        commandBuffer.addCompletedHandler { (cmdBuffer) in
            dispatch_semaphore_signal(dispatchSemaphore)
        }
        commandBuffer.commit()
    }
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        
    }
}