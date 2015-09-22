//
//  PixelShaderView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/16/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit
import simd

//TODO: write buffered texture view where the texture content swaps out randomly every second
// - init to make it look like a surface
//TODO: write pixelshader texture & view, revert texturedQuadRenderer to displaying image.
// - properly scale pixelshader
// - move pixel randomization to GPU compute function

// audio visualization with a randomized texturedquad, where the colors shift by the current input's max amplitude

class PixelShaderView: MetalView {
    
}

class PixelShaderViewController: NSViewController {
    var renderer: TexturedQuadRenderer!
    var metalView: MetalView!
    var pixelTexture: MetalTexture?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        setupRenderer()
        metalView = PixelShaderView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer.configure(metalView)
        renderer.uniformScale = float4(1.0, 1.0, 1.0, 1.0)
        positionTexture()
        
        let bufferTexture = renderer.inTexture as! BufferTexture<TexPixel2D>
        bufferTexture.writePixels(bufferTexture.randomPixels())
        pixelTexture = bufferTexture
        metalView.metalViewDelegate = renderer
        
        self.view.addSubview(metalView)
        setupGestures()
    }
    
    func setupRenderer() {
        renderer = TexturedQuadRenderer()
    }

    func positionTexture() {
        renderer.object!.modelRotation = float4(1.0, 0.0, 0.0, 90.0)
        renderer.object!.modelPosition = float4(0.0, 0.0, 2.0, 1.0)
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

