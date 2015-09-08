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
import MetalKit

class MetalLooperController: BaseMetalController, EZAudioPlayerDelegate, EZAudioFFTDelegate, MetalViewControllerDelegate {
    var player: EZAudioPlayer!
    var audioFile: EZAudioFile!
    
    @IBOutlet weak var btnPlay: NSButton!
    
    let fftWindowSize:vDSP_Length = 4096
    let fileUrl = NSBundle.mainBundle().URLForResource("get-to-the-choppa", withExtension: "mp3")
    //    let fileUrl = NSBundle.mainBundle().URLForResource("good-guys", withExtension: "mp3")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.player = EZAudioPlayer(delegate: self)
        self.player.shouldLoop = true
        self.audioFile = EZAudioFile(URL: fileUrl)
        self.player.audioFile = self.audioFile
        
        setupPlayerNotifications()
        
        self.metalViewControllerDelegate = self
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
        
    }
    
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
    }
    
    func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        
    }
    
    override func setupRenderPipeline() {
        
    }
    
}