//
//  MetalController.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/8/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

//https://developer.apple.com/library/prerelease/ios/samplecode/MetalKitEssentials/Introduction/Intro.html#//apple_ref/doc/uid/TP40016233-Intro-DontLinkElementID_2
// http://metalbyexample.com/introduction-to-compute/
// http://metalbyexample.com/introduction-to-compute/
// - https://github.com/FlexMonkey/MetalKit-Particles/tree/master/OSXMetalParticles

import Foundation
import Cocoa
import MetalKit

class MetalController: NSViewController, MetalViewDelegate {
    
    
    // [1,,x] [x2]
    // [,1,y] [y2] ....
    // [,,1z] [z2]
    // [,,,1] [1 ]
    
    var metalView: MetalTriangleView!
    var pipelineStateDescriptor: MTLRenderPipelineDescriptor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        metalView = MetalTriangleView(frame: rect, device: MTLCreateSystemDefaultDevice())
        
        self.view.addSubview(metalView)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    //TODO: move to MetalTriangleView (partially?)
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        
        //create a render encoder & tell it to draw the triangle
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(metalView.pipelineState)
        renderEncoder.setVertexBuffer(metalView.vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        renderEncoder.endEncoding()
    }
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        
    }
}
