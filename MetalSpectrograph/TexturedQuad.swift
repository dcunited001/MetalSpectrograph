//
//  TexturedQuad.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/10/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

//TODO: divide textured quad into multiple sub-triangles,
//  then, alter texture coords
//TODO: divide textured quad into dual sierpinski's gasket
//  and alter texture coords as above
//TODO: dynamically change mid-point of sierpinski's gasket

class TexturedQuad<T: protocol<Vertexable, Chunkable>>: Node<T>, RenderEncodable {
    
    // A ---- B
    // |      |
    // |      |
    // D ---- C
    
    class func texturedQuadVertices() -> [T] {
        return [
            // D A B
            T(chunks: [float4(-1.0, -1.0, 0.0, 1.0), float4(0.0, 0.0, 0.0, 0.0)]),
            T(chunks: [float4(-1.0,  1.0, 0.0, 1.0), float4(0.0, 1.0, 0.0, 0.0)]),
            T(chunks: [float4( 1.0,  1.0, 0.0, 1.0), float4(1.0, 1.0, 0.0, 0.0)]),
            
            // B C D
            T(chunks: [float4( 1.0,  1.0, 0.0, 1.0), float4(1.0, 1.0, 0.0, 0.0)]),
            T(chunks: [float4( 1.0, -1.0, 0.0, 1.0), float4(1.0, 0.0, 0.0, 0.0)]),
            T(chunks: [float4(-1.0, -1.0, 0.0, 1.0), float4(0.0, 0.0, 0.0, 0.0)])
        ]
    }
    
    var vertexIndex: Int = 0 // unsigned?  NSUInteger?
    var texCoordIndex: Int = 1
    var samplerIndex: Int = 0
    
    var size: CGSize = CGSize(width: 0.0, height: 0.0)
    var aspect: Float = 1.0
    var quadScale: float2 = float2(1.0)
    
    init(device: MTLDevice) {
        let quadVertices = TexturedQuad<T>.texturedQuadVertices()
        super.init(name: "TexturedQuad", vertices: quadVertices, device: device)
        
        //TODO: guard against nil device? guard in swift init?
        
        //create vertex buffer
        //  TODO: guard against fail/nil?
        vertexBuffer = device.newBufferWithBytes(quadVertices, length: vBytes, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        vertexBuffer.label = "quad vertices"
        
        bounds = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        
        aspect = 1.0
        quadScale = float2(1.0)
    }
    
    //    func setBounds(bounds: CGRect) -- cant override setBounds
    var bounds: CGRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0) {
        didSet {
            aspect = Float(abs(bounds.size.width / bounds.size.height))
            
            let newAspect:Float = 1.0/aspect
            var scale:float2 = float2(0.0);
            
            scale.x = newAspect * Float(size.width / bounds.size.width)
            scale.y = Float(size.height / bounds.size.height)
            
            let bNewScale = (scale.x != quadScale.x) || (scale.y != quadScale.y)
            if (bNewScale) {
                //update the scaling factor
                quadScale = scale
                
                //update the vertex buffer with the quad bounds
                //(simd::float4 *)[m_VertexBuffer contents]
                // - pointer to array .. do i need to typecast?
                var pVertices = vertexBuffer.contents() as! [float4]
                
                // how to check for failure in memory pointer retrieval?
                // - if casting fails, method blows up
                // - apple example uses if (pVertices != nil)
                
                pVertices[0].x = -quadScale.x
                pVertices[0].y = -quadScale.y
                
                pVertices[1].x = quadScale.x
                pVertices[1].y = -quadScale.y
                
                pVertices[2].x = -quadScale.x
                pVertices[2].y = quadScale.y
                
                pVertices[3].x = quadScale.x
                pVertices[3].y = -quadScale.y
                
                pVertices[4].x = -quadScale.x
                pVertices[4].y = quadScale.y
                
                pVertices[5].x = quadScale.x
                pVertices[5].y = quadScale.y
                
                //possible to simplify the above
                // - with vector/matrix multiplication?
            }
        }
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: vertexIndex)
    }
}