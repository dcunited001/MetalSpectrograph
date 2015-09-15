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

class TexturedQuadView: MetalView {
    
}

class TexturedQuadViewController: NSViewController {
    var renderer: TexturedQuadImgRenderer!
    var metalView: TexturedQuadView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        renderer = TexturedQuadImgRenderer()
        metalView = TexturedQuadView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer.configure(metalView)
        positionTexture()
        metalView.metalViewDelegate = renderer

        self.view.addSubview(metalView)
        setupGestures()
    }
    
    func positionTexture() {
        renderer.object!.modelRotation = float4(1.0, 0.0, 0.0, 90.0)
        renderer.object!.modelPosition = float4(0.0, 0.0, 1.0, 1.0)
    }
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    func setupGestures(){
        var pan = NSPanGestureRecognizer(target: self, action: Selector("pan:"))
        metalView.addGestureRecognizer(pan)
    }
    
    func pan(panGesture: NSPanGestureRecognizer){
        if panGesture.state == NSGestureRecognizerState.Changed{
            var pointInView = panGesture.locationInView(self.view)
            
            var xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            
            //            renderer.perspectiveAngle += xDelta
            //            renderer.perspectiveNear += yDelta/10
            //            renderer.perspectiveFar += xDelta
            //            renderer.projectionEye += [0.0, 0.0, yDelta]
            //            renderer.modelRotation += [0.0, 0.0, yDelta, 30*xDelta]
            //            renderer.object?.modelPosition += [0.0, 0.0, yDelta, 0.0]
            //            renderer.object?.modelPosition += [0.0, 0.0, 0.0, yDelta]
            //            renderer.object?.modelRotation += [0.0, 0.0, yDelta, 30*xDelta]
//                        renderer.object?.modelRotation += [0.0, 0.0, yDelta, 60*xDelta]
            renderer.object?.modelRotation += [0.0, 0.0, 0.0, 60*xDelta]
//              renderer.object?.modelPosition += [xDelta, 0.0, yDelta, 0.0]
            renderer.object?.modelPosition += [0.0, 0.0, yDelta, 0.0]
            //                        renderer.object?.modelScale += [xDelta, yDelta, 0.0, 0.0]
            
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
    }
}
