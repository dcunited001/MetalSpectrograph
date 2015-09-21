//
//  Generators.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/17/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

// TODO: ComputeDelegateProtocol?

class ComputeGenerator {
    var kernelFunction: MTLFunction!
    var device: MTLDevice!
    var library: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    
    var size: CGSize!
    
    var computePipelineState: MTLComputePipelineState?
    var computeFunctionName = "compute_function"
    
    init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.library = device.newDefaultLibrary()
        self.commandQueue = device.newCommandQueue()
        self.size = size
    }
    
    func configure() {
        setupComputePipeline()
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
        // override in subclass
    }
    
    func encode(computeEncoder: MTLComputeCommandEncoder) {
        
    }
    
    func getThreadExecutionWidth() -> Int {
        return computePipelineState!.threadExecutionWidth
    }
    
    func getThreadsPerThreadgroup(threadExecutionWidth: Int) -> MTLSize {
        // override in subclass
        return MTLSize()
    }
    
    func getThreadgroupsPerGrid(threadExecutionWidth: Int) -> MTLSize {
        // override in subclass
        return MTLSize()
    }
    
    func execute(commandBuffer: MTLCommandBuffer) {
        let computeEncoder = commandBuffer.computeCommandEncoder()
        computeEncoder.setComputePipelineState(computePipelineState!)
        encode(computeEncoder)
        
        let threadExecutionWidth = getThreadExecutionWidth()
        let threadsPerThreadgroup = getThreadsPerThreadgroup(threadExecutionWidth)
        let threadgroupsPerGrid = getThreadgroupsPerGrid(threadExecutionWidth)
        
        print(threadExecutionWidth, threadsPerThreadgroup, threadgroupsPerGrid)

        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
    }
}

