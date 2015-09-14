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

class BufferTexture: MetalTexture {
    var pixelSize:Int = sizeof(float4)
    
    var pixels:[float4] = [
        float4(1.0, 1.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        
        float4(1.0, 1.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        
        float4(1.0, 1.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        
        float4(1.0, 1.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        
        float4(1.0, 1.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0),
        float4(1.0, 1.0, 1.0, 1.0)
    ]
    convenience override init() {
        self.init(size: CGSize(width: 10,height: 10))
    }
    
    init(size: CGSize) {
        super.init()
        format = MTLPixelFormat.RGBA16Float
        width = Int(size.width)
        height = Int(size.height)
    }
    
    func calcBytesPerRow() -> Int {
        return width * pixelSize
//        return width * height * 4
    }
    
    override func finalize(device: MTLDevice) -> Bool {
        let pTexDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(format, width: width, height: height, mipmapped: false)
        
        target = pTexDesc.textureType
        texture = device.newTextureWithDescriptor(pTexDesc)
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture?.replaceRegion(region, mipmapLevel: 0, withBytes: pixels + pixels + pixels + pixels, bytesPerRow: calcBytesPerRow())
        
        return true
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