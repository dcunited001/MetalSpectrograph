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
    
    @IBOutlet weak var slideScaleX: NSSlider!
    @IBOutlet weak var slideScaleY: NSSlider!
    @IBOutlet weak var slideScaleZ: NSSlider!
    
    @IBOutlet weak var slideTransformX: NSSlider!
    @IBOutlet weak var slideTransformY: NSSlider!
    @IBOutlet weak var slideTransformZ: NSSlider!
    
    @IBOutlet weak var slideRotateX: NSSlider!
    @IBOutlet weak var slideRotateY: NSSlider!
    @IBOutlet weak var slideRotateZ: NSSlider!
    @IBOutlet weak var slideRotateTheta: NSSlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: 0, y:0, width: self.view.frame.width, height: self.view.frame.height)
        renderer = CubeRenderer()
        metalView = CubeView(frame: rect, device: MTLCreateSystemDefaultDevice())
        renderer.configure(metalView)
        positionObject()
//        initSliders()
        metalView.metalViewDelegate = renderer
        self.view.addSubview(metalView)
        setupGestures()
    }
    
    func initSliders() {
        slideScaleX.minValue = 0.0
        slideScaleX.maxValue = 5.0
        slideScaleY.minValue = 0.0
        slideScaleY.maxValue = 5.0
        slideScaleZ.minValue = 0.0
        slideScaleZ.maxValue = 5.0
        slideScaleX.floatValue = renderer.object!.modelScale.x
        slideScaleY.floatValue = renderer.object!.modelScale.y
        slideScaleZ.floatValue = renderer.object!.modelScale.z
        
        slideTransformX.minValue = -10.0
        slideTransformX.maxValue = 10.0
        slideTransformY.minValue = -10.0
        slideTransformY.maxValue = 10.0
        slideTransformZ.minValue = -10.0
        slideTransformZ.maxValue = 10.0
        slideTransformX.floatValue = renderer.object!.modelPosition.x
        slideTransformY.floatValue = renderer.object!.modelPosition.y
        slideTransformZ.floatValue = renderer.object!.modelPosition.z
        
        slideRotateX.minValue = -1.0
        slideRotateX.maxValue = 1.0
        slideRotateY.minValue = -1.0
        slideRotateY.maxValue = 1.0
        slideRotateZ.minValue = -1.0
        slideRotateZ.maxValue = 1.0
        slideRotateTheta.minValue = -540.0
        slideRotateTheta.maxValue = 540.0
        slideRotateX.floatValue = renderer.object!.modelRotation.x
        slideRotateY.floatValue = renderer.object!.modelRotation.y
        slideRotateZ.floatValue = renderer.object!.modelRotation.z
        slideRotateTheta.floatValue = renderer.object!.modelRotation.w
    }
    
    func positionObject() {
        renderer.object?.modelPosition = float4(0.0, 0.0, 1.0, 1.0)
        renderer.object?.modelScale = float4(0.2, 0.2, 0.2, 1.0)
    }
    
    let panSensivity:Float = 5.0
    var lastPanLocation: CGPoint!
    
    func setupGestures(){
//        var pan = NSPanGestureRecognizer(target: self, action: Selector("updateObjectToSliderValues:"))
        var pan = NSPanGestureRecognizer(target: self, action: Selector("pan:"))
        metalView.addGestureRecognizer(pan)
    }

    func updateObjectToSliderValues(panGesture: NSPanGestureRecognizer) {
        renderer.object?.modelPosition = [slideTransformX.floatValue, slideTransformY.floatValue, slideTransformZ.floatValue, 1.0]
        print(renderer.object?.modelScale)
        renderer.object?.modelScale = [slideScaleX.floatValue, slideScaleY.floatValue, slideScaleZ.floatValue, 1.0]
        renderer.object?.modelRotation = [slideRotateX.floatValue, slideRotateY.floatValue, slideRotateZ.floatValue, slideRotateTheta.floatValue]
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
            //            renderer.object?.modelRotation += [0.0, 0.0, yDelta, 60*xDelta]
//                        renderer.object?.modelRotation += [0.0, 0.0, 0.0, 60*xDelta]
//            renderer.object?.modelPosition += [xDelta, 0.0, yDelta, 0.0]
            renderer.object?.modelPosition += [xDelta, 0.0, yDelta, 0.0]
//                        renderer.object?.modelScale += [xDelta, yDelta, 0.0, 0.0]
            
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
    }
}