//
//  Generators.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/17/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

class ComputeGenerator {
    var kernelFunction: MTLFunction!
    var device: MTLDevice!
    var library: MTLLibrary!
    var size: CGSize!
    
    var computePipelineState: MTLComputePipelineState!
    var computeFunctionName = "compute_function"
    
    init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.library = device.newDefaultLibrary()
        self.size = size
        
        setupComputePipeline()
    }
    
    func configure() {
        prepareBuffers()
    }
    
    func setupComputePipeline() {
        kernelFunction = library.newFunctionWithName(computeFunctionName)
        do {
            try computePipelineState = device.newComputePipelineStateWithFunction(kernelFunction)
        } catch(let err) {
            print("Failed to create pipeline state, error \(err)")
        }
    }
    
    func prepareBuffers() {
        
    }
    
    func encode(computeEncoder: MTLComputeCommandEncoder) {
        
    }
    
    func execute(commandBuffer: MTLCommandBuffer) {
        let commandEncoder = commandBuffer.computeCommandEncoder()
        commandEncoder.setComputePipelineState(computePipelineState)
        
    }
}

class NoiseGenerator: ComputeGenerator {
    
}

