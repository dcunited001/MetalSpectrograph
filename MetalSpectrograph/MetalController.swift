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
    
    let vertexData:[Float] = [
        0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0]
    
    var vertexBuffer: MTLBuffer! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        setupMetalLayer()
        
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        
        print("vertexData: \(dataSize)")
        
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        
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

}
