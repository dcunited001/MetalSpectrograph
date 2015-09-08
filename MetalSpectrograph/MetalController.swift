//
//  MetalController.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/8/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit


class MetalController: NSViewController {
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var displayLink: CVDisplayLink?
    
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    // [1,,x] [x2]
    // [,1,y] [y2] ....
    // [,,1z] [z2]
    // [,,,1] [1 ]
    
    var vertexBuffer: MTLBuffer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        setupMetalLayer()
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        setupRenderPipeline()
        commandQueue = device.newCommandQueue()
        
//        var displayLinkPointer: Unmanaged<CVDisplayLink>?
        var displayLinkPointer: UnsafeMutablePointer<CVDisplayLink?> = UnsafeMutablePointer<CVDisplayLink?>.alloc(1)
        var error: CVReturn = CVDisplayLinkCreateWithActiveCGDisplays(displayLinkPointer)
        if (error != kCVReturnSuccess) {
            print("DisplayLink created with error \(error)")
            displayLink = nil
        }
        displayLink = displayLinkPointer.memory //get value at pointer
        
        //(CVDisplayLink, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>) -> CVReturn
//        CVDisplayLinkSetOutputHandler(displayLink!) { (dLink, timestamp, timestamp2, optionFlags, optionFlagsPointer) -> CVReturn in
//            return self.render()
//        }
        
        //(CVDisplayLink, UnsafePointer<CVTimeStamp>, UnsafePointer<CVTimeStamp>, CVOptionFlags, UnsafeMutablePointer<CVOptionFlags>, UnsafeMutablePointer<Void>)
        CVDisplayLinkSetOutputCallback(displayLink!,
            { (displayLink, timestamp, timestamp2, optionFlags, optionFlagsPointer, displayContext) -> CVReturn in
                let self_ = UnsafeMutablePointer<MetalController>(displayContext).memory
                self_.render()
                return 0
        }, UnsafeMutablePointer<MetalController>(unsafeAddressOf(self)))
        
        error = CVDisplayLinkStart(displayLink!)
        print(error)
        print(kCVReturnDisplayLinkCallbacksNotSet)
    }
    
    func render() -> CVReturn {
        var drawable = metalLayer.nextDrawable()
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable!.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        //create a command buffer
        let commandBuffer = commandQueue.commandBuffer()
        
        //create a render encoder & tell it to draw the triangle
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
        
        return kCVReturnSuccess
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func setupMetalLayer() {
        view.layer = view.makeBackingLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer!.frame
        view.layer!.addSublayer(metalLayer)
    }
    
    func setupRenderPipeline() {
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch(let err) {
            print("Failed to create pipeline state, error \(err)")
        }
        
    }

}
