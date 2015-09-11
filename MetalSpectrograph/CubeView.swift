//
//  CubeViewController.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit
import simd

class CubeView: MetalView {
    override func setupRenderPassDescriptor(drawable: CAMetalDrawable) {
        renderPassDescriptor!.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor!.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
    }
}

class CubeViewController: NSViewController {
    var renderer: CubeRenderer!
    var metalView: CubeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y:0, width: self.view.frame.width, height: self.view.frame.height)
        renderer = CubeRenderer()
        metalView = CubeView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer.configure(metalView)
        metalView.metalViewDelegate = renderer
        self.view.addSubview(metalView)

    }
}