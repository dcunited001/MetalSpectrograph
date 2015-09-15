//
//  CubeRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

//TODO: refactor buffers - premultiply projection & world model
//TODO: refactor to avoid var cube = object as! Cube<ColorVertex>

class CubeRenderer: BaseRenderer {
    
    override init() {
        super.init()
        
        //vertexShaderName = "uniform_color_morph_triangle_vertex"
        vertexShaderName = "continuous_uniform_color_morph_triangle_vertex"
        fragmentShaderName = "basic_triangle_fragment"
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        guard prepareObject() else {
            print("Failed to create Cube")
            return
        }
    }
    
    func prepareObject() -> Bool {
        object = Cube<ColorVertex>(device: device!)
        return true
    }
    
    override func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        let cube = object as! Cube<ColorVertex>
        
        cube.rotateForTime(timeSinceLastUpdate) { obj in
            return 3.0
        }
        cube.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/4) *
                float4(0.5, 0.5, 1.0, 0.0)
        }
//        object!.translateForTime(timeSinceLastUpdate) { obj in
//            return -sin(Float(timeSinceStart)/2) * float4(-0.5, 0.5, 0.0, 0.0)
//////            return -sin(Float(timeSinceStart)/2) * float4(0.1, 0.1, -1.0, 0.0)
//        }
        
//        cube.scaleForTime(timeSinceLastUpdate) { obj in
////            return float4(1.0, 1.0, 1.0, 0.0)
//            return -sin(Float(timeSinceStart)*2) * float4(0.5, 0.5, 0.5, 0.0)
////            return -sin(Float(timeSinceStart)*2) * float4(1.0, 0.6, 0.3, 0.0)
//        }
        object!.updateModelMatrix() // if params are dirty
    }
}
