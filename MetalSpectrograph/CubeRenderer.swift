//
//  CubeRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

class CubeRenderer: MetalRenderer, MetalViewDelegate, Projectable, Uniformable
{
    var pipelineState: MTLRenderPipelineState?
    var object: Cube<ColorVertex>?
    var size = CGSize()
    var startTime = CFAbsoluteTimeGetCurrent()
//    let vertexShaderName = "uniform_color_morph_triangle_vertex"
    let vertexShaderName = "continuous_uniform_color_morph_triangle_vertex"
//    let vertexShaderName = "basic_triangle_vertex"
    let fragmentShaderName = "basic_triangle_fragment"
    
    //Projectable
    var perspectiveFov:Float = 65.0
    var perspectiveAngle:Float = 35.0 // 35.0 for landscape
    var perspectiveAspect:Float = 1
    var perspectiveNear:Float = 0.01
    var perspectiveFar:Float = 100000000.0
    
    var projectionEye:float3 = [0.0, 0.0, 0.0]
    var projectionCenter:float3 = [0.0, 0.0, 1.0]
    var projectionUp:float3 = [0.0, 1.0, 0.0]
    var projectionMatrix:float4x4 = float4x4(diagonal: float4(1.0, 1.0, 1.0, 1.0))
    var projectionBuffer:MTLBuffer?
    var projectionPointer: UnsafeMutablePointer<Void>?
    
    // Uniformable
    var uniformBuffer:MTLBuffer?
    var uniformBufferId:Int = 1
    var modelScale = float4(1.0, 1.0, 1.0, 1.0)
    var modelPosition = float4(0.0, 0.0, 0.0, 1.0)
    var modelRotation = float4(1.0, 1.0, 1.0, 90)
    var modelMatrix: float4x4 = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
    var modelPointer: UnsafeMutablePointer<Void>?
    
    deinit {
        //TODO: release uniform and projection
    }
    
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
        
        self.projectionMatrix = calcProjectionMatrix()
        prepareProjectionBuffer(device!)
        updateProjectionBuffer()
        
        prepareUniformBuffer(device!)
        initModelMatrix()
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
        super.encode(renderEncoder)
        renderEncoder.pushDebugGroup("encode basic cube")
        renderEncoder.setRenderPipelineState(pipelineState!)
        object!.encode(renderEncoder)
        renderEncoder.setVertexBuffer(projectionBuffer, offset: 0, atIndex: 2)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 3)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: object!.vCount, instanceCount: 1)
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
    
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
        self.projectionMatrix = calcProjectionMatrix()
        self.modelMatrix = calcModelMatrix()

        updateProjectionBuffer()
        updateUniformBuffer()
        
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
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        
        object!.rotateForTime(timeSinceLastUpdate) { obj in
            return 3.0
        }
        object!.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/4) *
                float4(0.5, 0.5, 1.0, 0.0)
        }
//        object!.translateForTime(timeSinceLastUpdate) { obj in
//            return -sin(Float(timeSinceStart)/2) * float4(-0.5, 0.5, 0.0, 0.0)
//////            return -sin(Float(timeSinceStart)/2) * float4(0.1, 0.1, -1.0, 0.0)
//        }
        object!.scaleForTime(timeSinceLastUpdate) { obj in
//            return float4(1.0, 1.0, 1.0, 0.0)
            return -sin(Float(timeSinceStart)*2) * float4(0.5, 0.5, 0.5, 0.0)
//            return -sin(Float(timeSinceStart)*2) * float4(1.0, 0.6, 0.3, 0.0)
        }
        object!.modelMatrix = object!.calcModelMatrix()
        object!.updateUniformBuffer()
    }
}
