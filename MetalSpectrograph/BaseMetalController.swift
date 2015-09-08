//
//  BaseMetalController.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/8/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit

let AAPLBuffersInflightBuffers: Int = 3;

protocol MetalViewControllerDelegate: class {
    // updates game state
    func updateLogic(timeSinceLastUpdate: CFTimeInterval)
    
    // renders objects for frame
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
}

class BaseMetalController: NSViewController, MTKViewDelegate {
    
    var inflightSemaphore: dispatch_semaphore_t?
    
    var _view: MTKView!
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var displayLink: CVDisplayLink?
    
    var lastFrameStart: CFAbsoluteTime!
    var thisFrameStart: CFAbsoluteTime!
    
    weak var metalViewControllerDelegate: MetalViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        self._view = (self.view as! MTKView)
        _view.delegate = self
        _view.device = device
        
        inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInflightBuffers)
        commandQueue = device.newCommandQueue()
        setupRenderPipeline()
        
        lastFrameStart = CFAbsoluteTimeGetCurrent()
        thisFrameStart = CFAbsoluteTimeGetCurrent()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange: CGSize) {
        self.reshape()
    }
    
    func drawInMTKView(view: MTKView) {
        lastFrameStart = thisFrameStart
        thisFrameStart = CFAbsoluteTimeGetCurrent()
        
        self.metalViewControllerDelegate?.updateLogic(CFTimeInterval(thisFrameStart - lastFrameStart))
        
        autoreleasepool { () -> () in
            self.render(view)
        }
    }
    
    func reshape() {
        //        let aspect: CGFloat = fabs(self.view.bounds.size.width / self.view.bounds.size.height)
    }
    
    func render(view: MTKView) {
        let renderPassDescriptor = view.currentRenderPassDescriptor
        let drawable = view.currentDrawable
        let commandBuffer = commandQueue.commandBuffer()
        
        if (drawable != nil) {
            self.metalViewControllerDelegate?.renderObjects(drawable!, renderPassDescriptor: renderPassDescriptor!, commandBuffer: commandBuffer)
        }
        
        // hmm drawable! will still blow up here if nil
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
    }
    
    func setupRenderPipeline() {
        //override
    }
    
}
