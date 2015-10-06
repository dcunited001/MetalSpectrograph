//
//  MetalTexture.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/10/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit
import Quartz
import simd

class MetalTexture {
    var texture: MTLTexture?
    var target = MTLTextureType.Type2D
    var format = MTLPixelFormat.RGBA8Unorm
    var width: Int = 0
    var height: Int = 0
    var depth: Int = 1
    var flip = true
    
    init() {
        
    }
    
    deinit {
        texture = nil
    }
    
    func finalize(device: MTLDevice) -> Bool {
        //TODO: refactor some of the ImageTexture code here?
        return false
    }
}


// TODO: refactor pixelable protocol
//   and abstract `var color: float4` to `var color: T //T: Pixelable>`
struct TexPixel2D: Colorable {
    var color: float4
    
    init(chunks: [float4]) {
        self.color = chunks[0]
    }
    
    init(color: float4) {
        self.color = color
    }
    
    func toChunks() -> [float4] {
        return [color]
    }
    
    static func chunkSize() -> Int {
        return sizeof(TexPixel2D)
    }
}

class BufferTexture<T: Colorable>: MetalTexture {
    var pixelSize:Int = sizeof(T)
    private var pixelsPtr: UnsafeMutablePointer<Void> = nil
    private var pixelsVoidPtr: COpaquePointer?
    private var pixelsVertexPtr: UnsafeMutablePointer<T>?
    let pixelsAlignment:Int = 0x1000
    
//    var textureResourceOptions = MTLResourceOptions.CPUCacheModeDefaultCache
    var textureResourceOptions:MTLResourceOptions = .CPUCacheModeWriteCombined
    
    var pixelsDefault:[T] = [
        T(chunks: [float4(1.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 0.0, 1.0)]),
        
        T(chunks: [float4(1.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(1.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 0.0, 1.0)]),
        
        T(chunks: [float4(1.0, 0.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(1.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 0.0, 1.0, 1.0)]),
        
        T(chunks: [float4(0.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(1.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 1.0, 1.0)]),
        
        T(chunks: [float4(0.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(0.0, 1.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 0.0, 1.0)]),
        T(chunks: [float4(1.0, 0.0, 1.0, 1.0)]),
        T(chunks: [float4(1.0, 1.0, 0.0, 1.0)])
    ]
    
    convenience override init() {
        self.init(size: CGSize(width: 64,height: 64))
    }
    
    init(size: CGSize) {
        super.init()
        format = MTLPixelFormat.RGBA32Float
        width = Int(size.width)
        height = Int(size.height)
    }
    
    override func finalize(device: MTLDevice) -> Bool {
        let texDesc = createTextureDesc()
        
        initPixels()
        initTexture(device, textureDescriptor: texDesc)
        return true
    }
    
    func initPixels() {
        pixelsPtr = malloc(calcTotalBytes())
        memset(pixelsPtr, 0, calcTotalBytes())
    }
    
    func initTexture(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
        texture = device.newTextureWithDescriptor(textureDescriptor)
    }
    
    func createTextureDesc() -> MTLTextureDescriptor {
        let texDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format, width: width, height: height, mipmapped: false)
        target = texDesc.textureType
        
        return texDesc
    }
    
    func writePixels(pixels: [T]) {
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replaceRegion(region, mipmapLevel: 0, withBytes: pixels, bytesPerRow: calcBytesPerRow())
    }
    
    func calcTotalPages(bytes: Int) -> Int {
        return (bytes / pixelsAlignment) + 1
    }
    
    func calcBytesPerRow() -> Int {
        return width * sizeof(T)
    }
    
    func calcTotalBytes() -> Int {
        return calcTotalBytes(width, h: height)
    }
    
    func calcTotalBytes(w: Int, h: Int) -> Int {
        print(w, h)
        return w * h * sizeof(T)
    }

    func randomPixels() -> [T] {
        print(Float(arc4random())/Float(UInt32.max))
        // no idea why i can't return type T .. takes forever to build too.  says "too complex"
        return (0...calcTotalBytes())
            .lazy
            .map { _ in self.randomPixel() }
            .map { T(chunks: [$0]) }
    }

    func randomPixel() -> float4 {
        return float4(Float(arc4random())/Float(UInt32.max), Float(arc4random())/Float(UInt32.max), Float(arc4random())/Float(UInt32.max), 1.0)
//        return float4(rand,1,1,1)
//        return float4(Float(i*4) / 4.0))
        //        return float4((i * 4) / Float(16.0), i * 8 / 16.0, i * 16 / 16.0, 1.0)
    }
}

@available(iOS 9.0, *)
class SharedBufferTexture<T: Colorable>: BufferTexture<T> {
    
    override init(size: CGSize) {
        super.init(size: size)
//        textureResourceOptions = MTLResourceOptions.StorageModeShared
        
        //TODO: choice of: 
        // - subclass EZAudioFFT to change pointer type to T  (ColorVertex)
        //   - list of fft return data is already processed elementwise with vDSP calls  ...  or is it?
        //   - probably need to subclass EZAudioFFT anyways
        // - compute function to preprocess MTLBuffer of floats into gpu-write only RAM
        //   - going to need a compute function anyways, when translating from float4 => mesh
    }
    
    override func finalize(device: MTLDevice) -> Bool {
        //TODO: readd NSAVAILABLE
        // after editing the line below in MTLBuffer.h - and removing NS_AVAILABLE_IOS(8_0)
        //- (id <MTLTexture>)newTextureWithDescriptor:(MTLTextureDescriptor*)descriptor offset:(NSUInteger)offset bytesPerRow:(NSUInteger)bytesPerRow NS_AVAILABLE_IOS(8_0);
        // => failed assertion `MTLResourceOptions (0x0) contains invalid/unsupported StorageMode.'
        // womp womp, no .StorageModeShared for OSX =/

//        texture = texBuffer!.newTextureWithDescriptor(texDesc, offset: 0, bytesPerRow: calcBytesPerRow())
        //TODO: can't use this method in iOS
        // - and not sure why @available directive isn't working above

        writePixels(pixelsDefault)
        
        return true
    }
    
    override func initPixels() {
        let totalBytes = calcTotalBytes(width, h: height)
        posix_memalign(&pixelsPtr, pixelsAlignment, totalBytes)
        pixelsVoidPtr = COpaquePointer(pixelsPtr)
        pixelsVertexPtr = UnsafeMutablePointer<T>(pixelsVoidPtr!)
        
        //        let totalBytes = calcTotalBytes()
        //        pixelsPtr = malloc(totalBytes)
        //        writePixels(pixelsDefault)
        //        memset(pixelsPtr, 170, calcTotalBytes())
        //        memset(pixelsPtr, 85, calcTotalBytes())
        //        pixelsVoidPtr = COpaquePointer(pixelsPtr)
        //        pixelsVertexPtr = UnsafeMutablePointer<T>(pixelsVoidPtr!)
    }
    
    override func initTexture(device: MTLDevice, textureDescriptor: MTLTextureDescriptor) {
//        texture = texBuffer!.newTextureWithDescriptor(textureDescriptor, offset: 0, bytesPerRow: calcBytesPerRow())
    }
    
    override func writePixels(pixels: [T]) {
        memcpy(pixelsVertexPtr!, pixels, calcTotalBytes())
    }
    
}

class ImageTexture: MetalTexture {
    var path: NSString
    
    convenience override init() {
        self.init(name: "Default", ext:"jpg")
    }
    
    init(name: String, ext: String) {
        path = NSBundle.mainBundle().pathForResource(name, ofType: ext)!
        super.init()
    }

    override func finalize(device: MTLDevice) -> Bool {
        guard let imgData = NSData.dataWithContentsOfMappedFile(path as String) else {
            print("Couldn't load image: \(path)")
            return false
        }
        
        guard let nsImage = NSBitmapImageRep(data: imgData as! NSData),
            let pImage = nsImage.CGImage else {
            print("Couldn't decode image data: \(path)")
            return false
        }
        
        guard let pColorSpace = CGColorSpaceCreateDeviceRGB() else {
            print("Couldn't load color space.")
            return false
        }
        
        width = Int(CGImageGetWidth(pImage))
        height = Int(CGImageGetHeight(pImage))
        let rowBytes = width * 4
        
        guard let pContext = CGBitmapContextCreate(nil, width, height, 8, rowBytes, pColorSpace, CGImageAlphaInfo.PremultipliedLast.rawValue) else {
            print("Couldn't load context.")
            return false
        }
        
        let bounds = CGRectMake(0.0, 0.0, CGFloat(width),
            CGFloat(height))
        CGContextClearRect(pContext, bounds)
        
        if (flip) {
            CGContextTranslateCTM(pContext, CGFloat(width), CGFloat(height))
            CGContextScaleCTM(pContext, -1.0, -1.0)
        }

        CGContextDrawImage(pContext, bounds, pImage)
        
        let pTexDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format, width: width, height: height, mipmapped: false)
        
        target = pTexDesc.textureType
        texture = device.newTextureWithDescriptor(pTexDesc)
        
        let pPixels = CGBitmapContextGetData(pContext)
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replaceRegion(region, mipmapLevel: 0, withBytes: pPixels, bytesPerRow: rowBytes)
        
        return true
    }
    
}