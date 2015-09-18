//
//  AudioPixelShaderView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/16/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

//TODO: map random tex coords to vertices on a polygon with this texture
//TODO: wrap textured quad in a lattice
// - compute function to generate lattice vertices, with appropriate texcoords (or the same ones lol)
// - compute function to update vertices for the lattice based on audio input and the surrounding vertices
// - update the lattice wrapping for the texture while preserving approximation of the lattice tensor values

import Cocoa
import MetalKit
import simd
import EZAudio

class AudioPixelShaderView: PixelShaderView {
    
}

class AudioPixelShaderViewController: PixelShaderViewController, EZMicrophoneDelegate {
    var microphone: EZMicrophone!
    var colorShiftChangeRate: Float = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.microphone = EZMicrophone(delegate: self)
        microphone.startFetchingAudio()
    }
    
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        dispatch_async(dispatch_get_main_queue(), {
            (self.renderer as! AudioPixelShaderRenderer).colorShift += self.colorShiftChangeRate * abs(buffer[0].memory)
        })
    }
    
    override func setupRenderer() {
        renderer = AudioPixelShaderRenderer()
    }
}

class AudioPixelShaderRenderer: TexturedQuadRenderer {
    var colorShift: Float = 0 {
        didSet {
            if colorShift >= 1.0 {
                colorShift -= 1.0
            }
        }
    }
    private var colorShiftPtr: UnsafeMutablePointer<Void>!
    private var colorShiftBuffer: MTLBuffer!
    
    override init() {
        super.init()
        
        fragmentShaderName = "texQuadFragmentColorShift"
        rendererDebugGroupName = "Encode AudioPixelShader"
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        setupColorShiftBuffer()
    }
    
    func setupColorShiftBuffer() {
        colorShiftBuffer = device!.newBufferWithLength(sizeof(Float), options: .CPUCacheModeDefaultCache)
        colorShiftPtr = colorShiftBuffer.contents()
    }
    
    func setColorShiftBuffer(val: Float) {
        memcpy(colorShiftPtr!, &colorShift, sizeof(Float))
    }
    
    override func encodeFragmentBuffers(renderEncoder: MTLRenderCommandEncoder) {
        super.encodeFragmentBuffers(renderEncoder)
        setColorShiftBuffer(self.colorShift)
        renderEncoder.setFragmentBuffer(colorShiftBuffer, offset: 0, atIndex: 0)
    }
    
}


