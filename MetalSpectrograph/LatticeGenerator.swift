//
//  LatticeGenerator.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/17/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

// TODO: tensors for manipulating lattice
// - tensor representing & updating the immediate state
// - 'differentiated' tensor representing the state change across time
// - each vertex has n adjacent nodes, even edge nodes, where n also == the number of params for tensor
//   - for now, treat as infinite lattice for simplicity
//   - thus, each vertex can be assigned a unique id in a 1D array
//   - but also, each vertex's specific tensor attribute can be addressed with (vertexId, attrId)
// - define a method for passing tensor information to adjacent vertices
//   - this will likely be in the vertex or fragment shader

protocol Lattice {
    var lattice: Modelable? { get set }
//    var adjacentNodeCount: { get set }
    var tensorBuffer: MTLBuffer? { get set }
    var tensorBufferId: Int { get set }
    
    // define indexing for vertices
    func getVertex(id: Int) -> Vertexable
    
    // define method for generating lattice points
    func generateLattice(node: Modelable)
    
    // define tensors for updating the lattice

    // write to buffer
}

class Lattice2D<N: protocol<Vertexable, Chunkable>>: Node<N>, Lattice, RenderEncodable {
    var lattice: Modelable?
    var tensorBuffer: MTLBuffer?
    var tensorBufferId: Int = 1
    
    func getVertex(id: Int) -> Vertexable {
        return N(chunks: [float4(1.0, 1.0, 1.0, 1.0)])
    }
    
    func generateLattice(node: Modelable) {
        // assume 6 points input, if a base node
        // read in each triangle
        // convert it into 4 triangles
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        //write vertexbuffer
        //write tensorbuffer
    }
}

// LatticeStruct: Node<V: Vertexable>
// - a basic lattice configuration to pass to a generator 
//   to avoid recursive construction

// TODO: 3D lattice generator for platonic solids
// - where you can create crystals of polygons

//class Lattice3D<N: Vertexable>: Node<N>, Lattice {
//    
//}

// TODO: can generator a lattice from a set of vertices that lie on the same plane
// TODO: 3d lattice generator?
// TODO: histogram lattice generator: generates a lattice, where
//   each quadrilateral or hexagon can be raised

// L = Lattice Type
class LatticeGenerator<T>: ComputeGenerator {
    //can be initialized given 
    // - a set of vertices
    // - or another lattice of the same dimensionality
}

class BisectionLatticeGenerator<T>: LatticeGenerator<T> {
    
}

//generates a rectangular lattice, composed of triangle pairs
class QuadLatticeGenerator<T>: LatticeGenerator<T> {
    
}


//generates a uniform lattice composed of equilateral triangles
class HexLatticeGenerator<T>: LatticeGenerator<T> {
    
}

////TODO: takes a textured quad and processes the vertices to result in a list of vertices
//// for triangles and their texture coords
//class TexturedLatticeGenerator {
//    
//}
//
