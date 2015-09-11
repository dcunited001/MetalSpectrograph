//
//  CubeRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

class CubeRenderer: MetalRenderer, MetalViewDelegate {
    var pipelineState: MTLRenderPipelineState?
    var object: Cube<ColorVertex>?
    var size = CGSize()
    
    override func configure(view: MetalView) {
        super.configure(view)
        guard preparePipelineState(view) else {
            print("Failed creating a compiled pipeline state object!")
            return
        }
        
        guard prepareObject() else {
            print("Failed to create Cube")
            return
        }
    }
    
    func preparePipelineState(view: MetalView) -> Bool {
        guard let fragmentProgram = shaderLibrary?.newFunctionWithName("basic_triangle_fragment") else {
            print("Couldn't load basic_triangle_fragment")
            return false
        }
        
        guard let vertexProgram = shaderLibrary?.newFunctionWithName("basic_triangle_vertex") else {
            print("Couldn't load basic_triangle_vertex")
            return false
        }
        
        //setup render pipeline descriptor
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        //setup render pipeline state
        do {
            try pipelineState = device!.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch(let err) {
            print("Failed to create pipeline state, error \(err)")
        }
        
        return true
    }
    
    func prepareObject() -> Bool {
        object = Cube<ColorVertex>(device: device!)
        return true
    }
    
    override func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup("encode basic cube")
        renderEncoder.setRenderPipelineState(pipelineState!)
        object!.encode(renderEncoder)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: object!.vCount, instanceCount: 1)
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
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
    
    func updateLogic(timeSinseLastUpdate: CFTimeInterval) {
        
        
    }
    
}