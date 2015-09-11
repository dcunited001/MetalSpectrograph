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

class BasicTriangleView: MetalView {
    override func render() {
        // setup CFAbsoluteTimeGetCurrent()
        
        renderPassDescriptor = currentRenderPassDescriptor
        
        // test renderpassdescriptor
        let commandBuffer = commandQueue.commandBuffer()
        
        guard let drawable = currentDrawable else
        {
            print("currentDrawable returned nil")
            
            return
        }
        
        setupRenderPassDescriptor(drawable)
        self.metalViewDelegate?.renderObjects(drawable, renderPassDescriptor: renderPassDescriptor!, commandBuffer: commandBuffer)
        
        self.metalViewDelegate?.afterRender?()
    }
    
    override func setupRenderPassDescriptor(drawable: CAMetalDrawable) {
        renderPassDescriptor!.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor!.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
    }
}

class MetalTriangleController: NSViewController {
    var renderer: BasicTriangleRenderer!
    var metalView: BasicTriangleView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y:0, width: self.view.frame.width, height: self.view.frame.height)
        renderer = BasicTriangleRenderer()
        metalView = BasicTriangleView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer.configure(metalView)
        metalView.metalViewDelegate = renderer
        self.view.addSubview(metalView)
    }
}

