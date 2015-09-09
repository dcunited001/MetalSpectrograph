//
//  MetalTriangleView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit

class MetalTriangleView: MetalView {
    
    var vertexBuffer: MTLBuffer!
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    var pipelineState: MTLRenderPipelineState!

    override func setupRenderPipeline() {
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = self.device!.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        //setup render programs
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
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
    }
}