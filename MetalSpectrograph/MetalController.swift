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

let AAPLBuffersInflightBuffers: Int = 3;

class MetalController: NSViewController, MTKViewDelegate {
    
    var inflightSemaphore: dispatch_semaphore_t?
    
    var _view: MTKView!
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var displayLink: CVDisplayLink?
    
    var vertexBuffer: MTLBuffer!
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    // [1,,x] [x2]
    // [,1,y] [y2] ....
    // [,,1z] [z2]
    // [,,,1] [1 ]
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        self._view = (self.view as! MTKView)
        _view.delegate = self
        _view.device = device
        
        inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInflightBuffers)
        commandQueue = device.newCommandQueue()
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        setupRenderPipeline()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange: CGSize) {
        self.reshape()
    }
    
    func drawInMTKView(view: MTKView) {
        autoreleasepool { () -> () in
            self.render()
        }
    }
    
    func reshape() {
//        let aspect: CGFloat = fabs(self.view.bounds.size.width / self.view.bounds.size.height)
    }
    
    func render() -> CVReturn {
        let renderPassDescriptor = _view.currentRenderPassDescriptor
        let drawable = _view.currentDrawable
        let commandBuffer = commandQueue.commandBuffer()
        
        renderPassDescriptor!.colorAttachments[0].texture = drawable!.texture
        renderPassDescriptor!.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        //create a render encoder & tell it to draw the triangle
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor!)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
        
        return kCVReturnSuccess
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
