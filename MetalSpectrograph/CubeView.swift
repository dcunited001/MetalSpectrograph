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
        renderPassDescriptor!.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
}

//TODO: Panable
protocol Panable {
    var panSensivity:Float { get set } // = 5.0
    var lastPanLocation: CGPoint! { get set }
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
        renderer.perspectiveAspect = Float(rect.width / rect.height)
        renderer.modelScale = float4(1.0, Float(rect.width / rect.height), 1.0, 1.0)
        positionObject()
        metalView.metalViewDelegate = renderer
        self.view.addSubview(metalView)
        setupGestures()
    }
    
    func positionObject() {
        renderer.object?.modelPosition = float4(0.0, 0.0, 1.0, 1.0)
        renderer.object?.modelScale = float4(1.0, 1.0, 1.0, 1.0)
    }
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    func setupGestures(){
        var pan = NSPanGestureRecognizer(target: self, action: Selector("pan:"))
        self.view.addGestureRecognizer(pan)
    }
    
    func pan(panGesture: NSPanGestureRecognizer){
        if panGesture.state == NSGestureRecognizerState.Changed{
            var pointInView = panGesture.locationInView(self.view)

            var xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            
            
//            renderer.projectionEye += [yDelta, xDelta, 0.0]
            renderer.modelRotation += [0.0, 0.0, yDelta, 30*xDelta]
//            renderer.object?.modelPosition += [yDelta, xDelta, 0.0, 0.0]
//            renderer.object?.modelRotation += [yDelta, xDelta, 0.0, 0.0]
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        } 
    }
}