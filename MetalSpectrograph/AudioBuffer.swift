//
//  AudioBuffer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/22/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Metal
import simd
import EZAudio

// these classes should help streamline creation of visualizations by handline buffer data access
// but don't know anything about the objects they expose, only bytes

protocol MetalBuffer {
    var buffer: MTLBuffer? { get set }
    var bufferId: Int? { get set }
    var bytecount: Int? { get set }
    var resourceOptions: MTLResourceOptions? { get set }
    
    func prepareBuffer(device: MTLDevice, options: MTLResourceOptions)
    func writeCompute(renderEncoder: MTLComputeCommandEncoder)
    func writeVertex(renderEncoder: MTLRenderCommandEncoder)
    func writeFragment(renderEncoder: MTLRenderCommandEncoder)
}

extension MetalBuffer {
    func prepareBuffer(device: MTLDevice, options: MTLResourceOptions) {
        //either set buffer/bufferId or subclass and configure it
    }
    
    func writeCompute(renderEncoder: MTLComputeCommandEncoder) {
        renderEncoder.setBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
//    func writeComputeBytes() 
    
    func writeVertex(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
//    func writeVertexBytes()
    
    func writeFragment(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setFragmentBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
}

class ShaderBuffer: MetalBuffer {
    var buffer: MTLBuffer?
    var bufferId: Int?
    var bytecount: Int?
    var resourceOptions: MTLResourceOptions?
    
    
}

// manages writing texture data
class TextureBuffer: ShaderBuffer {
    
}

class CircularBuffer: ShaderBuffer {
    
}

// highly performant circular buffer (requires iOS and CPU/GPU integrated architecture)
// TODO: decide if generic is required?
@available(iOS 9.0, *)
class NoCopyBuffer<T>: ShaderBuffer {
    var stride:Int?
    var elementSize:Int = sizeof(T)
    private var bufferPtr: UnsafeMutablePointer<Void>?
    private var bufferVoidPtr: COpaquePointer?
    private var bufferDataPtr: UnsafeMutablePointer<T>?
    var bufferAlignment: Int = 0x1000 // for NoCopy buffers, memory needs needs to be mutliples of 4096
    
    func prepareMemory(bytecount: Int) {
        self.bytecount = bytecount
        bufferPtr = UnsafeMutablePointer<Void>.alloc(bytecount)
        posix_memalign(&bufferPtr!, bufferAlignment, bytecount)
        bufferVoidPtr = COpaquePointer(bufferPtr!)
        bufferDataPtr = UnsafeMutablePointer<T>(bufferVoidPtr!)
    }
    
    func prepareBuffer(device: MTLDevice, options: MTLResourceOptions) {
        //TODO: common deallocator?
        buffer = device.newBufferWithBytesNoCopy(bufferPtr!, length: bytecount!, options: .StorageModeShared, deallocator: nil)
    }

    //TODO: decide on how to use similar data access patterns when buffer is specific to a texture
//    override func initTexture(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
//        //        texture = texBuffer!.newTextureWithDescriptor(textureDescriptor, offset: 0, bytesPerRow: calcBytesPerRow())
//    }
    
    //mechanism for writing specific bytes
    func writeBuffer(data: [T]) {
        memcpy(bufferDataPtr!, data, bytecount!)
    }
}

// TODO: class ScalarBuffer: MetalBuffer {} ??

class WaveformBuffer: CircularBuffer {
    //TODO: magnitude scaling for waveform?  or already clamped floats?
}

class FFTBuffer: CircularBuffer {
    
}

class FFTAverageBuffer: CircularBuffer {
    
}


// writes bytes as input for a buffer, without using MTLBuffer
protocol ShaderInput: class {
    var bufferId: Int? { get set }
    var bytecount: Int? { get set }
    var resourceOptions: MTLResourceOptions? { get set }
    
    func writeComputeBytes(renderEncoder: MTLComputeCommandEncoder)
    func writeVertexBytes(renderEncoder: MTLRenderCommandEncoder)
    func writeFragmentBytes(renderEncoder: MTLRenderCommandEncoder)
}

extension ShaderInput {
    func writeComputeBytes(renderEncoder: MTLComputeCommandEncoder) {
        
    }
    
    func writeVertexBytes(renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
    func writeFragmentBytes(renderEncoder: MTLRenderCommandEncoder) {
        
    }
}

class BaseMetalInput: ShaderInput {
    var bufferId: Int?
    var bytecount: Int?
    var resourceOptions: MTLResourceOptions?
    
}

// generalize to WaveformMetadataBuffer?
class WaveformAbsAvereageInput: BaseMetalInput {
    
    func configure(device: MTLDevice, options: MTLResourceOptions) {
        device.newBufferWithLength(bytecount!, options: options)
    }
    
    func writeFragment(renderEncoder: MTLRenderCommandEncoder) {
        // TODO: update pointer for buffer
        // TODO: set data -- how to make data generic?
//        renderEncoder.setFragmentBytes( , offset: 0, atIndex: bufferId!)
    }
    
    //TODO: calculate for stereo
    class func waveformAverage(buffer:UnsafeMutablePointer<UnsafeMutablePointer<Float>>, bufferSize: UInt32, numberOfChannels: UInt32) -> Float {
        
        var absVector = UnsafeMutablePointer<Float>.alloc(Int(bufferSize))
        var vectorSumResult = UnsafeMutablePointer<Float>.alloc(1)
        
        vDSP_vabs(buffer[0], 1, absVector, 1, UInt(bufferSize))
        vDSP_sve(absVector, 1, vectorSumResult, UInt(bufferSize))
        
        return vectorSumResult.memory / Float(bufferSize)
    }
    
}




