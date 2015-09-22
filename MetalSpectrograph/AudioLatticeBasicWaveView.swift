//
//  BasicWaveLattice.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/18/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit
import simd
import EZAudio

class AudioLatticeBasicWaveView: MetalView {
    
}

class AudioLatticeBasicWaveController: AudioPixelShaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderer.object!.setModelUniformsFrom((renderer as! AudioLatticeRenderer).originalObject!)
        setupGestures()
    }
    
    override func setupRenderer() {
        renderer = AudioLatticeRenderer()
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        dispatch_async(dispatch_get_main_queue(), {
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            
            (self.renderer as! AudioPixelShaderRenderer).colorShift += self.colorShiftChangeRate * absAverage
        })
    }
    
    override func pan(panGesture: NSPanGestureRecognizer){
        if panGesture.state == NSGestureRecognizerState.Changed{
            var pointInView = panGesture.locationInView(self.view)
            
            var xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            
            renderer.object?.modelPosition += [xDelta, 0.0, yDelta, 0.0]
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
    }
}

//TODO: check that texture is loaded (ensure pointer is valid)

class AudioLatticeRenderer: AudioPixelShaderRenderer {
    typealias VertexType = TexturedVertex
    typealias LG = QuadLatticeGenerator<Lattice2D<VertexType>, TexturedQuad<VertexType>>
    
    //    var object: Node<VertexType>
    var originalObject: protocol<RenderEncodable,Modelable,VertexBufferable>?
    var latticeGenerator: LG?
    
    // TODO: DrawPrimitives is not drawing all the triangles, but doesn't seem to be performance related.
    var latticeRows = 15
    var latticeCols = 15
    
    // circular buffer
    
    override init() {
        super.init()
        
        //fragmentShaderName
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        latticeGenerator = LG(device: device!, size: CGSize(width: latticeCols, height: latticeRows))
        latticeGenerator!.configure()
        
        originalObject = object
        object = latticeGenerator!.generateLattice(object as! TexturedQuad<VertexType>)
    }
    
    override func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        let quad = object as! Lattice2D<TexturedVertex>
        
        quad.rotateForTime(timeSinceLastUpdate) { obj in
            return 3.0
        }
        quad.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/4) *
                float4(0.5, 0.5, 1.0, 0.0)
        }
        
        object!.updateModelMatrix()
        //update vertex lattice (possibly modulating rows & columns
    }
    
}

class ImageLatticeBasicWaveController: AudioPixelShaderViewController {
    
    override func setupTexture() {
        pixelTexture = renderer.inTexture as! ImageTexture
    }

    override func setupRenderer() {
        renderer = ImageLatticeRenderer()
    }
    
}

class ImageLatticeRenderer: AudioLatticeRenderer {
    let defaultFileName = "metaloopa"
    let defaultFileExt = "jpg"
    
    override init() {
        super.init()
        
        latticeRows = 15
        latticeCols = 15
    }
    
    override func prepareTexturedQuad(view: MetalView) -> Bool {
        inTexture = ImageTexture.init(name: defaultFileName as String, ext: defaultFileExt as String)
        inTexture?.texture
        
        guard inTexture!.finalize(device!) else {
            print("Failed to finalize ImageTexture")
            return false
        }
        
        inTexture!.texture!.label = "ImageTexture" as String
        size.width = CGFloat(inTexture!.texture!.width)
        size.width = CGFloat(inTexture!.texture!.width)
        
        object = TexturedQuad<TexturedVertex>(device: device!)
        
        return true
    }
    
}


