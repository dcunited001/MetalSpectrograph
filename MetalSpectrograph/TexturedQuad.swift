//
//  TexturedQuad.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/10/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

class TexturedQuad {
    struct TexCoords {
        static let cnt = 6
        static let sz = cnt * sizeof(float2)
        static let coords: [float2] = [
            float2(0.0, 0.0),
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            
            float2(1.0, 0.0),
            float2(0.0, 1.0),
            float2(1.0, 1.0)
        ]
    }
    
    struct Vertices {
        static let cnt = TexCoords.cnt
        static let sz = cnt * sizeof(float4)
        static let verts: [float4] = [
            float4(-1.0, -1.0, 0.0, 1.0),
            float4( 1.0, -1.0, 0.0, 1.0),
            float4(-1.0,  1.0, 0.0, 1.0),
            
            float4( 1.0, -1.0, 0.0, 1.0),
            float4(-1.0,  1.0, 0.0, 1.0),
            float4( 1.0,  1.0, 0.0, 1.0),
        ]
    }
    
    var vertexIndex: Int = 0 // unsigned?  NSUInteger?
    var texCoordIndex: Int = 1
    var samplerIndex: Int = 0
    
    var size: CGSize
    var aspect: Float
    var mScale: float2
    
    var mVertexBuffer: MTLBuffer
    var mTexCoordBuffer: MTLBuffer
    
    init?(device: MTLDevice) {
        //TODO: guard against nil device? guard in swift init?
        
        //create vertex buffer
        //  TODO: guard against fail/nil?
        mVertexBuffer = device.newBufferWithBytes(Vertices.verts, length: Vertices.sz, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        mVertexBuffer.label = "quad vertices"
        
        //create tex coord buffer
        //  TODO: guard against fail/nil?
        mTexCoordBuffer = device.newBufferWithBytes(TexCoords.coords, length: TexCoords.sz, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        mTexCoordBuffer.label = "quad texcoords"
        
        size = CGSize(width: 0.0, height: 0.0)
        bounds = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        aspect = 1.0
        mScale = float2(1.0)
    }
    
    //    func setBounds(bounds: CGRect) -- cant override setBounds
    var bounds: CGRect {
        didSet {
            aspect = Float(abs(bounds.size.width / bounds.size.height))
            
            let newAspect:Float = 1.0/aspect
            var scale:float2 = float2(0.0);
            
            scale.x = newAspect * Float(size.width / bounds.size.width)
            scale.y = Float(size.height / bounds.size.height)
            
            let bNewScale = (scale.x != mScale.x) || (scale.y != mScale.y)
            if (bNewScale) {
                //update the scaling factor
                mScale = scale
                
                //update the vertex buffer with the quad bounds
                //(simd::float4 *)[m_VertexBuffer contents]
                // - pointer to array .. do i need to typecast?
                var pVertices = mVertexBuffer.contents() as! [float4]
                
                // how to check for failure in memory pointer retrieval?
                // - if casting fails, method blows up
                // - apple example uses if (pVertices != nil)
                
                pVertices[0].x = -mScale.x
                pVertices[0].y = -mScale.y
                
                pVertices[1].x = mScale.x
                pVertices[1].y = -mScale.y
                
                pVertices[2].x = -mScale.x
                pVertices[2].y = mScale.y
                
                pVertices[3].x = mScale.x
                pVertices[3].y = -mScale.y
                
                pVertices[4].x = -mScale.x
                pVertices[4].y = mScale.y
                
                pVertices[5].x = mScale.x
                pVertices[5].y = mScale.y
                
                //possible to simplify the above
                // - with vector/matrix multiplication?
            }
        }
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(mVertexBuffer, offset: 0, atIndex: vertexIndex)
        renderEncoder.setVertexBuffer(mTexCoordBuffer, offset: 0, atIndex: texCoordIndex)
    }
}