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
    var startTime = CFAbsoluteTimeGetCurrent()
//    let vertexShaderName = "uniform_color_morph_triangle_vertex"
    let vertexShaderName = "continuous_uniform_color_morph_triangle_vertex"
//    let vertexShaderName = "basic_triangle_vertex"
    let fragmentShaderName = "basic_triangle_fragment"
    
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
        guard let fragmentProgram = shaderLibrary?.newFunctionWithName(fragmentShaderName) else {
            print("Couldn't load basic_triangle_fragment")
            return false
        }
        
        guard let vertexProgram = shaderLibrary?.newFunctionWithName(vertexShaderName) else {
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
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        
        object!.rotateForTime(timeSinceLastUpdate) { obj in
            return 1.0
        }
        object!.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/2) * float3(0.5, 0.5, 1.0)
        }
        object!.translateForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/2) * float3(0.1, 0.1, -1.0)
        }
        object!.scaleForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)*2) * float3(1.0, 0.6, 0.3)
        }
        object!.updateModelMatrix()
        object!.updateUniformBuffer()
    }
    
    
    
}