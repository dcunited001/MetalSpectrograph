//
//  ParticleView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit
import GameplayKit

class ParticleLabView: MetalView, MetalViewDelegate {
    let imageWidth: UInt
    let imageHeight: UInt
    
    private var imageWidthFloatBuffer: MTLBuffer!
    private var imageHeightFloatBuffer: MTLBuffer!
    
    weak var particleLabDelegate: ParticleLabDelegate?
    var computePipelineState: MTLComputePipelineState!
    
    let bytesPerRow: Int
    let region: MTLRegion
    let blankBitmapRawData : [UInt8]
    
    private var kernelFunction: MTLFunction!
    
    private var errorFlag:Bool = false
    
    private var threadsPerThreadgroup:MTLSize!
    private var threadgroupsPerGrid:MTLSize!
    
    var particleCount: Int
    let alignment:Int = 0x4000
    let particlesMemoryByteSize:Int
    
    private var particlesMemory:UnsafeMutablePointer<Void> = nil
    private var particlesVoidPtr: COpaquePointer!
    private var particlesParticlePtr: UnsafeMutablePointer<ParticleLab>!
    private var particlesParticleBufferPtr: UnsafeMutableBufferPointer<ParticleLab>!

    private var gravityWellParticle = ParticleLab(A: Vector4(x: 0, y: 0, z: 0, w: 0),
        B: Vector4(x: 0, y: 0, z: 0, w: 0),
        C: Vector4(x: 0, y: 0, z: 0, w: 0),
        D: Vector4(x: 0, y: 0, z: 0, w: 0))
    
    let particleSize = sizeof(ParticleLab)
    let particleColorSize = sizeof(ParticleLabColor)
    let boolSize = sizeof(Bool)
    let floatSize = sizeof(Float)
    
    var particleColor = ParticleLabColor(R: 1, G: 0.5, B: 0.2, A: 1)
    var dragFactor: Float = 0.97
    var respawnOutOfBoundsParticles = true
    var clearOnStep = true
    
    private var frameStartTime: CFAbsoluteTime!
    private var frameNumber = 0
    
    var particlesBufferNoCopy: MTLBuffer!

//    convenience override init() {
//        let defaultSize = CGSize(width: 800,height: 600)
//        let numParticles = ParticleLabCount.FourMillion
//        self.init(size: defaultSize, numParticles: numParticles)
//    }

    init(size: CGSize, numParticles: ParticleLabCount) {
        particleCount = numParticles.rawValue
        self.imageWidth = UInt(size.width)
        self.imageHeight = UInt(size.height)
        
        bytesPerRow = Int(4 * imageWidth)
        
        region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        blankBitmapRawData = [UInt8](count: Int(imageWidth * imageHeight * 4), repeatedValue: 0)
        particlesMemoryByteSize = particleCount * sizeof(ParticleLab)
        
        super.init(frame: CGRect(x: 0,y: 0,width: size.width,height: size.height), device: nil)
        self.metalViewDelegate = self
        
        particlesBufferNoCopy = device!.newBufferWithBytesNoCopy(particlesMemory, length: Int(particlesMemoryByteSize), options: MTLResourceOptions.StorageModeShared, deallocator: nil)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beforeSetupMetal() {
        setupParticles()
    }
    
    override func afterSetupMetal() {
        
    }
    
    deinit {
        free(particlesMemory)
    }
    
    override func setupRenderPipeline() {
        kernelFunction = defaultLibrary.newFunctionWithName("particleRendererShader")
        
        setupComputePipelineState()
        setupImageBuffers()
    }
    
    func setupComputePipelineState() {
        do {
            try computePipelineState = device!.newComputePipelineStateWithFunction(kernelFunction!)
        } catch(let err) {
            //fatalError() ?
            print("Failed to create pipeline state, error \(err)")
        }
        
        let threadExecutionWidth = computePipelineState.threadExecutionWidth
        
        threadsPerThreadgroup = MTLSize(width:threadExecutionWidth,height:1,depth:1)
        threadgroupsPerGrid = MTLSize(width:particleCount / threadExecutionWidth, height:1, depth:1)
    }
    
    func setupImageBuffers() {
        var imageWidthFloat = Float(imageWidth)
        var imageHeightFloat = Float(imageHeight)
        
        imageWidthFloatBuffer =  device!.newBufferWithBytes(&imageWidthFloat, length: sizeof(Float), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        imageHeightFloatBuffer = device!.newBufferWithBytes(&imageHeightFloat, length: sizeof(Float), options: MTLResourceOptions.CPUCacheModeDefaultCache)
    }
    
    private func setupParticles() {
        posix_memalign(&particlesMemory, alignment, particlesMemoryByteSize)
        
        particlesVoidPtr = COpaquePointer(particlesMemory)
        particlesParticlePtr = UnsafeMutablePointer<ParticleLab>(particlesVoidPtr)
        particlesParticleBufferPtr = UnsafeMutableBufferPointer(start: particlesParticlePtr, count: particleCount)
        
        resetParticles()
        resetGravityWells()
    }
    
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
        
        let commandEncoder = commandBuffer.computeCommandEncoder()
        
        commandEncoder.setComputePipelineState(computePipelineState)
        
        commandEncoder.setBuffer(particlesBufferNoCopy, offset: 0, atIndex: 0)
        commandEncoder.setBuffer(particlesBufferNoCopy, offset: 0, atIndex: 1)
        
        commandEncoder.setBytes(&gravityWellParticle, length: particleSize, atIndex: 2)
        commandEncoder.setBytes(&particleColor, length: particleColorSize, atIndex: 3)
        
        commandEncoder.setBuffer(imageWidthFloatBuffer, offset: 0, atIndex: 4)
        commandEncoder.setBuffer(imageHeightFloatBuffer, offset: 0, atIndex: 5)
        
        commandEncoder.setBytes(&dragFactor, length: floatSize, atIndex: 6)
        commandEncoder.setBytes(&respawnOutOfBoundsParticles, length: boolSize, atIndex: 7)
        
        if clearOnStep
        {
            drawable.texture.replaceRegion(self.region, mipmapLevel: 0, withBytes: blankBitmapRawData, bytesPerRow: bytesPerRow)
        }
        
        //TODO: fix access for texture
        
        let textureDesc = MTLTextureDescriptor()
//        textureDesc.usage = MTLTextureUsage(rawValue: MTLTextureUsage.)
        
//        print(drawable.texture.usage)
//        drawable.texture.usage = .MTLTextureUsageShaderWrite
        commandEncoder.setTexture(drawable.texture, atIndex: 0)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
            {
                particleLabDelegate?.particleLabDidUpdate()
        }
    }

    func updateLogic(timeSinseLastUpdate: CFTimeInterval) {
        
    }
    
    func resetGravityWells()
    {
        setGravityWellProperties(gravityWell: .One, normalisedPositionX: 0.25, normalisedPositionY: 0.75, mass: 10, spin: 0.2)
        setGravityWellProperties(gravityWell: .Two, normalisedPositionX: 0.25, normalisedPositionY: 0.25, mass: 10, spin: -0.2)
        setGravityWellProperties(gravityWell: .Three, normalisedPositionX: 0.75, normalisedPositionY: 0.25, mass: 10, spin: 0.2)
        setGravityWellProperties(gravityWell: .Four, normalisedPositionX: 0.75, normalisedPositionY: 0.75, mass: 10, spin: -0.2)
    }
    
    func resetParticles(edgesOnly: Bool = false, distribution: Distribution = Distribution.Gaussian)
    {
        func rand() -> Float32
        {
            return Float(drand48() - 0.5) * 0.005
        }
        
        let imageWidthDouble = Double(imageWidth)
        let imageHeightDouble = Double(imageHeight)
        
        let randomSource = GKRandomSource()
        
        let randomWidth: GKRandomDistribution
        let randomHeight: GKRandomDistribution
        
        switch distribution
        {
        case .Gaussian:
            randomWidth = GKGaussianDistribution(randomSource: randomSource, lowestValue: 0, highestValue: Int(imageWidthDouble))
            randomHeight = GKGaussianDistribution(randomSource: randomSource, lowestValue: 0, highestValue: Int(imageHeightDouble))
            
        case .Uniform:
            randomWidth = GKShuffledDistribution(randomSource: randomSource, lowestValue: 0, highestValue: Int(imageWidthDouble))
            randomHeight = GKShuffledDistribution(randomSource: randomSource, lowestValue: 0, highestValue: Int(imageHeightDouble))
        }
        
        for index in particlesParticleBufferPtr.startIndex ..< particlesParticleBufferPtr.endIndex
        {
            var positionAX = Float(randomWidth.nextInt())
            var positionAY = Float(randomHeight.nextInt())
            
            var positionBX = Float(randomWidth.nextInt())
            var positionBY = Float(randomHeight.nextInt())
            
            var positionCX = Float(randomWidth.nextInt())
            var positionCY = Float(randomHeight.nextInt())
            
            var positionDX = Float(randomWidth.nextInt())
            var positionDY = Float(randomHeight.nextInt())
            
            if edgesOnly
            {
                let positionRule = Int(arc4random() % 4)
                
                if positionRule == 0
                {
                    positionAX = 0
                    positionBX = 0
                    positionCX = 0
                    positionDX = 0
                }
                else if positionRule == 1
                {
                    positionAX = Float(imageWidth)
                    positionBX = Float(imageWidth)
                    positionCX = Float(imageWidth)
                    positionDX = Float(imageWidth)
                }
                else if positionRule == 2
                {
                    positionAY = 0
                    positionBY = 0
                    positionCY = 0
                    positionDY = 0
                }
                else
                {
                    positionAY = Float(imageHeight)
                    positionBY = Float(imageHeight)
                    positionCY = Float(imageHeight)
                    positionDY = Float(imageHeight)
                }
            }
            
            let particle = ParticleLab(A: Vector4(x: positionAX, y: positionAY, z: rand(), w: rand()),
                B: Vector4(x: positionBX, y: positionBY, z: rand(), w: rand()),
                C: Vector4(x: positionCX, y: positionCY, z: rand(), w: rand()),
                D: Vector4(x: positionDX, y: positionDY, z: rand(), w: rand()))
            
            particlesParticleBufferPtr[index] = particle
        }
    }
    
    
    final func getGravityWellNormalisedPosition(gravityWell gravityWell: ParticleLabGravityWell) -> (x: Float, y: Float)
    {
        let returnPoint: (x: Float, y: Float)
        
        let imageWidthFloat = Float(imageWidth)
        let imageHeightFloat = Float(imageHeight)
        
        switch gravityWell
        {
        case .One:
            returnPoint = (x: gravityWellParticle.A.x / imageWidthFloat, y: gravityWellParticle.A.y / imageHeightFloat)
            
        case .Two:
            returnPoint = (x: gravityWellParticle.B.x / imageWidthFloat, y: gravityWellParticle.B.y / imageHeightFloat)
            
        case .Three:
            returnPoint = (x: gravityWellParticle.C.x / imageWidthFloat, y: gravityWellParticle.C.y / imageHeightFloat)
            
        case .Four:
            returnPoint = (x: gravityWellParticle.D.x / imageWidthFloat, y: gravityWellParticle.D.y / imageHeightFloat)
        }
        
        return returnPoint
    }
    
    final func setGravityWellProperties(gravityWellIndex gravityWellIndex: Int, normalisedPositionX: Float, normalisedPositionY: Float, mass: Float, spin: Float)
    {
        switch gravityWellIndex
        {
        case 1:
            setGravityWellProperties(gravityWell: .Two, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
            
        case 2:
            setGravityWellProperties(gravityWell: .Three, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
            
        case 3:
            setGravityWellProperties(gravityWell: .Four, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
            
        default:
            setGravityWellProperties(gravityWell: .One, normalisedPositionX: normalisedPositionX, normalisedPositionY: normalisedPositionY, mass: mass, spin: spin)
        }
    }
    
    final func setGravityWellProperties(gravityWell gravityWell: ParticleLabGravityWell, normalisedPositionX: Float, normalisedPositionY: Float, mass: Float, spin: Float)
    {
        let imageWidthFloat = Float(imageWidth)
        let imageHeightFloat = Float(imageHeight)
        
        switch gravityWell
        {
        case .One:
            gravityWellParticle.A.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.A.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.A.z = mass
            gravityWellParticle.A.w = spin
            
        case .Two:
            gravityWellParticle.B.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.B.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.B.z = mass
            gravityWellParticle.B.w = spin
            
        case .Three:
            gravityWellParticle.C.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.C.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.C.z = mass
            gravityWellParticle.C.w = spin
            
        case .Four:
            gravityWellParticle.D.x = imageWidthFloat * normalisedPositionX
            gravityWellParticle.D.y = imageHeightFloat * normalisedPositionY
            gravityWellParticle.D.z = mass
            gravityWellParticle.D.w = spin
        }
    }
    
}

protocol ParticleLabDelegate: NSObjectProtocol
{
    func particleLabDidUpdate()
    func particleLabMetalUnavailable()
    
    func particleLabStatisticsDidUpdate(fps fps: Int, description: String)
}

//  Since each Particle instance defines four particles, the visible particle count
//  in the API is four times the number we need to create.
enum ParticleLabCount: Int
{
    case HalfMillion = 131072
    case OneMillion =  262144
    case TwoMillion =  524288
    case FourMillion = 1048576
    case EightMillion = 2097152
    case SixteenMillion = 4194304
}

//  Paticles are split into three classes. The supplied particle color defines one
//  third of the rendererd particles, the other two thirds use the supplied particle
//  color components but shifted to BRG and GBR
struct ParticleLabColor
{
    var R: Float32 = 0
    var G: Float32 = 0
    var B: Float32 = 0
    var A: Float32 = 1
}

struct ParticleLab // Matrix4x4
{
    var A: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var B: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var C: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
    var D: Vector4 = Vector4(x: 0, y: 0, z: 0, w: 0)
}

// Regular particles use x and y for position and z and w for velocity
// gravity wells use x and y for position and z for mass and w for spin
struct Vector4
{
    var x: Float32 = 0
    var y: Float32 = 0
    var z: Float32 = 0
    var w: Float32 = 0
}

enum Distribution
{
    case Gaussian
    case Uniform
}

enum ParticleLabGravityWell
{
    case One
    case Two
    case Three
    case Four
}
