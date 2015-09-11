//
//  MetalTriangleView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit

class BasicTriangleView: MetalView {
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

