//
//  SpectrographController.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/7/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import EZAudio

class SpectrographController: NSViewController, EZAudioPlayerDelegate, EZAudioFFTDelegate {
    
    var fft: EZAudioFFTRolling!
    var player: EZAudioPlayer!
    var audioFile: EZAudioFile!
    let renderFFT = false
    
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    
    let fftWindowSize:vDSP_Length = 4096
    let fileUrl = NSBundle.mainBundle().URLForResource("get-to-the-choppa", withExtension: "mp3")
//    let fileUrl = NSBundle.mainBundle().URLForResource("good-guys", withExtension: "mp3")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = EZAudioPlayer(delegate: self)
        self.player.shouldLoop = false
        self.audioFile = EZAudioFile(URL: fileUrl)
        self.player.audioFile = self.audioFile
        
        setupAudioPlot()
        setupPlayerNotifications()
        setupFFT(self.player.output.inputFormat.mSampleRate)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func didClickPlay(sender: NSButton) {
        self.btnPlay.enabled = false
        self.player.play()
    }
    
    func setupPlayerNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        notificationCenter.addObserver(self, selector: "playerDidChangePlayState", name: EZAudioPlayerDidChangePlayStateNotification, object: nil)
    }
    
    func playerDidChangePlayState() {
        if !self.player.isPlaying {
            self.btnPlay.enabled = true
            self.player.seekToFrame(0)
        }
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, inAudioFile audioFile: EZAudioFile!) {
        if (renderFFT) {
            fft?.computeFFTWithBuffer(buffer[0], withBufferSize: bufferSize)
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.audioPlot.updateBuffer(buffer[0], withBufferSize: UInt32(bufferSize))
            })
        }
    }
    
    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length) {
        if (renderFFT) {
            dispatch_async(dispatch_get_main_queue(), {
                // [2048 x 1] array of floats
                //
                self.audioPlot.updateBuffer(fftData, withBufferSize: UInt32(bufferSize))
            })
        }
    }
    
    func setupFFT(sampleRate: Float64) {
        self.fft = EZAudioFFTRolling.fftWithWindowSize(fftWindowSize, sampleRate: Float(sampleRate), delegate: self)
    }
    
    func setupAudioPlot() {
        audioPlot.plotType = EZPlotType.Buffer;
        audioPlot.backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        audioPlot.color = NSColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
}