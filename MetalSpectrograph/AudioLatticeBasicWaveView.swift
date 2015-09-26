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
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        preferredFramesPerSecond = 60
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AudioLatticeBasicWaveController: AudioPixelShaderViewController {
    
    var updateWaveformBufferCounter = 0
    var updateWaveformBufferEvery = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderer.object!.setModelUniformsFrom((renderer as! AudioLatticeRenderer).originalObject!)
        setupGestures()
    }

// TODO: not sure why this causes so many issues with nil
//    override func setupMetalView(frame: CGRect) -> MetalView {
//        return AudioLatticeBasicWaveView(frame: frame, device: MTLCreateSystemDefaultDevice())
//    }
    
    override func setupRenderer() {
        renderer = AudioLatticeRenderer()
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        //TODO: decide on async callback
        dispatch_async(dispatch_get_main_queue(), {
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            
            self.updateWaveformBufferCounter++
            
            (self.renderer as! AudioLatticeRenderer).colorShift += self.colorShiftChangeRate * absAverage
            
            if self.updateWaveformBufferCounter % self.updateWaveformBufferEvery == 0 {
                (self.renderer as! AudioLatticeRenderer).waveformBuffer!.writeBufferRow(buffer[0])
            }
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
    var latticeRows = 25
    var latticeCols = 20
    
    var waveformBuffer: CircularBuffer?
    var latticeConfigInput = BaseInput<QuadLatticeConfig>()
    
    override init() {
        super.init()

        vertexShaderName = "audioLatticeCircularWave"
        fragmentShaderName = "texQuadFragmentPeriodicColorShift"
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        latticeGenerator = LG(device: device!, size: CGSize(width: latticeCols, height: latticeRows))
        latticeGenerator!.configure()
        
        originalObject = object
        object = latticeGenerator!.generateLattice(object as! TexturedQuad<VertexType>)
        
        prepareLatticeConfig()
        prepareBuffers()
        scaleQuadForLattice()
    }
    
    func prepareLatticeConfig() {
        latticeConfigInput.data = QuadLatticeConfig(size: int2(Int32(latticeCols), Int32(latticeRows)))
        latticeConfigInput.bufferId = 4
    }
    
    func prepareBuffers() {
        prepareWaveformBuffer()
    }
    
    func prepareWaveformBuffer() {
        let numCachedWaveforms = latticeRows + 1
        let samplesPerUpdate = 512
        
        waveformBuffer = WaveformBuffer()
        waveformBuffer!.bufferId = 2
        waveformBuffer!.prepareMemory(samplesPerUpdate * numCachedWaveforms * sizeof(Float))
        waveformBuffer!.prepareCircularParams(samplesPerUpdate)
        waveformBuffer!.circularParams!.bufferId = 3
        waveformBuffer!.prepareBuffer(device!)
    }
    
    func scaleQuadForLattice() {
        object!.modelScale *= float4(Float(latticeRows)/10.0, Float(latticeCols)/10.0, 1.0, 1.0)
    }
    
    override func encodeVertexBuffers(renderEncoder: MTLRenderCommandEncoder) {
        super.encodeVertexBuffers(renderEncoder)
        waveformBuffer!.writeVertex(renderEncoder)
        latticeConfigInput.writeVertexBytes(renderEncoder)
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
    
    var updateWaveformBufferCounter = 0
    var updateWaveformBufferEvery = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorShiftChangeRate = 0.05
    }
    
    override func setupTexture() {
        pixelTexture = renderer.inTexture as! ImageTexture
    }

    override func setupRenderer() {
        renderer = ImageLatticeRenderer()
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        dispatch_async(dispatch_get_main_queue(), {
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            
            self.updateWaveformBufferCounter++
            
            (self.renderer as! AudioLatticeRenderer).colorShift += self.colorShiftChangeRate * absAverage
            
            if self.updateWaveformBufferCounter % self.updateWaveformBufferEvery == 0 {
                (self.renderer as! AudioLatticeRenderer).waveformBuffer!.writeBufferRow(buffer[0])
            }
        })
    }
    
}

class ImageLatticeRenderer: AudioLatticeRenderer {
    let defaultFileName = "metaloopa"
    let defaultFileExt = "jpg"
    
    override init() {
        super.init()
        
        latticeRows = 50
        latticeCols = 20
        
        fragmentShaderName = "texQuadFragmentPeriodicColorShift"
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

class ImageLatticeFftController: ImageLatticeBasicWaveController {
    let fftWindowSize:vDSP_Length = 4096
    var fft: EZAudioFFTRolling!
    var micSampleRate: Double!
    
    var updateFftBufferCounter = 0
    var updateFftBufferEvery = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        micSampleRate = microphone.audioStreamBasicDescription().mSampleRate
        setupFFT(micSampleRate)
        
        //        renderer.object!.modelRotation = [0.0, 0.0, 1.0, 0.0]
        colorShiftChangeRate = 0.05
    }
    
    func setupFFT(sampleRate: Float64) {
        // no delegate on FFT
        self.fft = EZAudioFFTRolling.fftWithWindowSize(fftWindowSize, sampleRate: Float(sampleRate))
    }
    
    override func setupRenderer() {
        let fftRenderer = ImageLatticeFftRenderer()
        fftRenderer.fftWindowSize = fftWindowSize
        renderer = fftRenderer
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        dispatch_async(dispatch_get_main_queue(), {
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            let latticeRenderer = (self.renderer as! ImageLatticeFftRenderer)
            latticeRenderer.colorShift += self.colorShiftChangeRate * absAverage
            
            if self.fft != nil {
                self.updateFftBufferCounter++
                
                //TODO: deal with slow FFT init time more appropriately
                let fftVals = self.fft!.computeFFTWithBuffer(buffer[0], withBufferSize: bufferSize)
                
                // slow the rate of buffer updates
                if self.updateFftBufferCounter % self.updateFftBufferEvery == 0 {
                    latticeRenderer.fftBuffer!.writeBufferRow(fftVals)
                }
            }
        })
    }
    
    override func pan(panGesture: NSPanGestureRecognizer){
        if panGesture.state == NSGestureRecognizerState.Changed{
            var pointInView = panGesture.locationInView(self.view)
            
            var xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            
            renderer.object?.modelPosition += [0.0, 0.0, yDelta, 0.0]
            renderer.object?.modelRotation += [0.0, 0.0, 0.0, 90 * xDelta]
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
    }
}

class ImageLatticeFftRenderer: ImageLatticeRenderer {
    var fftWindowSize:vDSP_Length = 4096
    var fftBuffer: FFTBuffer?
//    var latticeConfigInput = BaseInput<QuadLatticeConfig>()
    
    override init() {
        super.init()
        
        latticeRows = 15
        latticeCols = 80
        fragmentShaderName = "texQuadFragmentPeriodicColorShift"
    }
    
    override func prepareBuffers() {
        prepareFftBuffers()
    }
    
    func prepareFftBuffers() {
        let numCachedFft = latticeRows + 1
        let fftSliceSize = Int(fftWindowSize / 2)
        
        fftBuffer = FFTBuffer()
        fftBuffer!.bufferId = 2
        fftBuffer!.prepareMemory(fftSliceSize * numCachedFft * sizeof(Float))
        fftBuffer!.prepareCircularParams(fftSliceSize)
        fftBuffer!.circularParams!.bufferId = 3
        //fftParams?
        fftBuffer!.prepareBuffer(device!)
    }
    
    override func encodeVertexBuffers(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(mvpBuffer, offset: 0, atIndex: mvpBufferId)
        fftBuffer!.writeVertex(renderEncoder)
        latticeConfigInput.writeVertexBytes(renderEncoder)
    }
    
    override func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        let quad = object as! Lattice2D<TexturedVertex>
        
//        quad.rotateForTime(timeSinceLastUpdate) { obj in
//            return 2.0
//        }
//        quad.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
//            return -sin(Float(timeSinceStart)/4) *
//                float4(0.5, 0.5, 1.0, 0.0)
//        }
        
        object!.updateModelMatrix()
        //update vertex lattice (possibly modulating rows & columns
    }
    
}

