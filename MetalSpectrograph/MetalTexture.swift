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
    var texBuffer: MTLBuffer?
    
    var pixelSize:Int = sizeof(T)
    private var pixelsPtr: UnsafeMutablePointer<Void> = nil
    private var pixelsVoidPtr: COpaquePointer?
    private var pixelsVertexPtr: UnsafeMutablePointer<T>?
    
    let pixelsAlignment:Int = 0x1000
    
//    var memPointer: UnsafeMutablePointer<UnsafeMutablePointer<Void>>
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
        
        let totalBytes = calcTotalBytes(width, h: height)
        posix_memalign(&pixelsPtr, pixelsAlignment, totalBytes)
        pixelsVoidPtr = COpaquePointer(pixelsPtr)
        pixelsVertexPtr = UnsafeMutablePointer<T>(pixelsVoidPtr!)
        
//        particlesParticleBufferPtr = UnsafeMutableBufferPointer(start: particlesParticlePtr, count: particleCount)
        
//        let totalPageBytes = calcTotalPages(totalBytes) * 4096
//        pixelsPointer = valloc(totalBytes)
//        pixelsPointer = malloc(totalBytes)
//        let memPointer: UnsafeMutablePointer<UnsafeMutablePointer<Void>> =
//        posix_memalign(memPointer, 4096, totalBytes)
//        pixelsPointer = memset(memPointer, 0, totalBytes)
    }
    
    func calcBytesPerRow() -> Int {
        return width * sizeof(T)
    }
    
    //hmmm do i deal with this using posix_memalign?
    func calcTotalPages(bytes: Int) -> Int {
        return (bytes / pixelsAlignment) + 1
    }
    
    func calcTotalBytes() -> Int {
        return calcTotalBytes(width, h: height)
    }
    
    func calcTotalBytes(w: Int, h: Int) -> Int {
        return w * h * sizeof(T)
    }
    
    override func finalize(device: MTLDevice) -> Bool {
        let texDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format, width: width, height: height, mipmapped: false)
        target = texDesc.textureType
        texDesc.resourceOptions = .StorageModeShared
        
        // after editing the line below in MTLBuffer.h - and removing NS_AVAILABLE_IOS(8_0)
        //- (id <MTLTexture>)newTextureWithDescriptor:(MTLTextureDescriptor*)descriptor offset:(NSUInteger)offset bytesPerRow:(NSUInteger)bytesPerRow NS_AVAILABLE_IOS(8_0);
        // => failed assertion `MTLResourceOptions (0x0) contains invalid/unsupported StorageMode.'
        // womp womp, no .StorageModeShared for OSX =/
        texBuffer = device.newBufferWithBytesNoCopy(pixelsVertexPtr!, length: calcTotalBytes(), options: .StorageModeShared, deallocator: nil)
        texture = texBuffer!.newTextureWithDescriptor(texDesc, offset: 0, bytesPerRow: calcBytesPerRow())

        writePixels(pixelsDefault)
        
        return true
    }
    
    func writePixels(pixels: [T]) {
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