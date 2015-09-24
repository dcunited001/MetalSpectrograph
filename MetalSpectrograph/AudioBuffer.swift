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

protocol SpectraMetalBuffer: class {
    var buffer: MTLBuffer? { get set }
    var bufferId: Int? { get set }
    var bytecount: Int? { get set }
    var resourceOptions: MTLResourceOptions? { get set }
    
    func prepareBuffer(device: MTLDevice, options: MTLResourceOptions)
    func writeCompute(encoder: MTLComputeCommandEncoder)
    func writeComputeParams(encoder: MTLComputeCommandEncoder)
    func writeVertex(encoder: MTLRenderCommandEncoder)
    func writeVertexParams(encoder: MTLRenderCommandEncoder)
    func writeFragment(encoder: MTLRenderCommandEncoder)
    func writeFragmentParams(encoder: MTLRenderCommandEncoder)
}

class SpectraBuffer: SpectraMetalBuffer {
    var buffer: MTLBuffer?
    var bufferId: Int?
    var bytecount: Int?
    var resourceOptions: MTLResourceOptions?
    
    func prepareBuffer(device: MTLDevice, options: MTLResourceOptions) {
        //either set buffer/bufferId or subclass and configure it
    }
    
    func writeCompute(encoder: MTLComputeCommandEncoder) {
        writeComputeParams(encoder)
        encoder.setBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
    func writeComputeParams(encoder: MTLComputeCommandEncoder) {
        // override in subclass
    }
    
    func writeVertex(encoder: MTLRenderCommandEncoder) {
        writeVertexParams(encoder)
        encoder.setVertexBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
    func writeVertexParams(encoder: MTLRenderCommandEncoder) {
        // override in subclass
    }
    
    func writeFragment(encoder: MTLRenderCommandEncoder) {
        writeFragmentParams(encoder)
        encoder.setFragmentBuffer(buffer!, offset: 0, atIndex: bufferId!)
    }
    
    func writeFragmentParams(encoder: MTLRenderCommandEncoder) {
        // override in subclass
    }
}

// manages writing texture data
//class TextureBuffer: ShaderBuffer {
//    
//}

// class TensorBuffer

struct CircularBufferParams {
    var stride: Int // in number of elements
    var start: Int
    var numElements: Int // TODO: anyway to access .count() in metal shader?
}

//TODO: dealloc mem!!!

// works with 1D and 2D.  need separate circular buffer for 3D.
class CircularBuffer: SpectraBuffer {
    var bufferAlignment: Int = 0x1000
    private var bufferPtr: UnsafeMutablePointer<Void>?
    private var currentRow: Int

    // TODO: set size of items in circular buffer
    var elementSize: Int = 4 // Default to float
    var numRows: Int?
    var circularParams: BaseInput<CircularBufferParams>?
    
    override init() {
        currentRow = 0
        super.init()
    }
    
    // circular buffers require writing the buffer and the startpoint
    
    func incrementBuffer() {
        if currentRow == (numRows! - 1) {
            resetBuffer()
        } else {
            currentRow++
        }
    }
    
    func resetBuffer() {
        currentRow = 0
    }
    
    func prepareMemory(bytecount: Int) {
        self.bytecount = bytecount
        bufferPtr = UnsafeMutablePointer<Void>.alloc(bytecount)
        posix_memalign(&bufferPtr!, bufferAlignment, bytecount)
    }
    
    func prepareCircularParams(stride: Int, start: Int = 0) {
        numRows = bytecount! / stride / elementSize
        circularParams = BaseInput<CircularBufferParams>()
        circularParams!.data = CircularBufferParams(stride: stride, start: start, numElements: bytecount! / elementSize)
    }
    
    override func prepareBuffer(device: MTLDevice, options: MTLResourceOptions = .CPUCacheModeWriteCombined) {
        // apparently 421KB is too many bytes
        buffer = device.newBufferWithBytesNoCopy(bufferPtr!, length: getAlignedBytecount(), options: .StorageModeManaged) { (ptr, bytes) in
            free(ptr)
        }
    }
    
    func writeBuffer(ptr: UnsafeMutablePointer<Void>) {
        memcpy(bufferPtr!, ptr, bytecount!)
    }
    
    func writeBufferRow(ptr: UnsafeMutablePointer<Void>) {
        let stride = circularParams!.data!.stride
        let colBytes = stride == 0 ? bytecount! : (bytecount! / stride)
        let rowBytes = stride * elementSize
        let startElement = currentRow * stride

        let startbyte = bufferPtr!.advancedBy(startElement * elementSize);
        
        memcpy(startbyte, ptr, rowBytes)
        circularParams!.data!.start = startElement
        //NOTE: looks pretty cool when didModifyRange is removed
//        buffer!.didModifyRange(NSMakeRange(startElement * elementSize, startElement * elementSize + rowBytes))
        buffer!.didModifyRange(NSMakeRange(0, bytecount!))
        incrementBuffer()
    }
    
    override func writeVertexParams(encoder: MTLRenderCommandEncoder) {
        super.writeVertexParams(encoder)
        circularParams!.writeVertexBytes(encoder)
    }
    
    func getAlignedBytecount() -> Int {
        return ((bytecount! + bufferAlignment) / bufferAlignment) * bufferAlignment
    }
    
    //TODO: writeFragmentParams
    //TODO: writeComputeParams
}

// TODO: class ScalarBuffer: MetalBuffer {} ??

class WaveformBuffer: CircularBuffer {
    //TODO: init stride to 512 (how to get this from EZAudio?)
    //TODO: magnitude scaling for waveform? or already clamped floats?
    //TODO: multiple channels of audio
    
    func updateWithWavefrom(buffer:UnsafeMutablePointer<UnsafeMutablePointer<Float>>, numberOfChannels: UInt32) {
        writeBufferRow(buffer[0])
    }
}

class FFTBuffer: CircularBuffer {
    // TODO: init stride to 2048 (how to get this?)
    //TODO: magnitude scaling?
    
    func updateWithFft(buffer:UnsafeMutablePointer<Float>, numberOfChannels: UInt32) {
        writeBufferRow(buffer)
    }
}

class FFTAverageBuffer: CircularBuffer {
    
}

// TODO: SpectrogramBuffer // texture buffer for fft data

// TODO: ManagedNoCopyBuffer ... should work in OSX, right?

// highly performant buffer (requires iOS and CPU/GPU integrated architecture)
// TODO: decide if generic is required?
@available(iOS 9.0, *)
class NoCopyBuffer<T>: SpectraBuffer {
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
    
    override func prepareBuffer(device: MTLDevice, options: MTLResourceOptions) {
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


// writes bytes as input for a buffer, without using MTLBuffer
protocol SpectraMetalInput: class {
    typealias InputType
    
    var data: InputType? { get set }
    var bufferId: Int? { get set }
    
    func writeComputeBytes(encoder: MTLComputeCommandEncoder)
    func writeVertexBytes(encoder: MTLRenderCommandEncoder)
    func writeFragmentBytes(encoder: MTLRenderCommandEncoder)
}

// genericize with float4 & float4x4
class SpectraInput<T>: SpectraMetalInput {
    //TODO: evaluate generic here
    typealias InputType = T
    
    var data: InputType? //TODO: can i use AnyObject here?
    var bufferId: Int?
    
    func writeComputeBytes(encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&data!, length: sizeof(InputType), atIndex: bufferId!)
    }
    
    func writeVertexBytes(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBytes(&data!, length: sizeof(InputType), atIndex: bufferId!)
    }
    
    func writeFragmentBytes(encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentBytes(&data!, length: sizeof(InputType), atIndex: bufferId!)
    }
}

// generalize to WaveformMetadataBuffer?
// TODO: set up struct to contain stereo data
class WaveformAbsAvereageInput: SpectraInput<Float> {
    
    // TODO: change updateData to receive Float as input?
    func updateData(buffer:UnsafeMutablePointer<UnsafeMutablePointer<Float>>, bufferSize: UInt32, numberOfChannels: UInt32) {
        data = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
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




