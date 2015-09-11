//
//  TexturedQuadView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

// copying from Apple's metal textured quad example, basically

import Cocoa
import MetalKit
import simd

//willEnterForeground
//didEnterBackground

class TexturedQuadViewController: NSViewController {
    var renderer: TexturedQuadImgRenderer!
    var metalView: TexturedQuadView!
    
    override func viewDidLoad() {
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        metalView = TexturedQuadView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer = TexturedQuadImgRenderer()
        metalView.metalViewDelegate = renderer

        renderer.configure(metalView)
        self.view.addSubview(metalView)
    }
    
}

class TexturedQuadView: MetalView {
    
}
