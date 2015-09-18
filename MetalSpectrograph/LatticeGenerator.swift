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
// - might be a good idea to just attach the tensor data directly to the vertex
//   - however i want to be able to update the tensor data in the vertex/fragment render
//   - also, if the compute functions are to be reused
//     - the vertex location needs to be mostly independent from the metadata

protocol Lattice {
    typealias VertexType
    
    var lattice: Modelable? { get set }
//    var adjacentNodeCount: { get set }
    var tensorBuffer: MTLBuffer? { get set }
    var tensorBufferId: Int { get set }
    
    // define indexing for vertices
    func getVertex(id: Int) -> Vertexable
    
    // define method for generating lattice points
//    func generateLattice(node: Modelable)
    
    // define tensors for updating the lattice

    // write to buffer
    
    init(name: String, vertices: [VertexType], device: MTLDevice)
}

class Lattice2D<V: protocol<Vertexable, Chunkable>>: Node<V>, Lattice, RenderEncodable {
    typealias VertexType = V
    
    var lattice: Modelable?
    var tensorBuffer: MTLBuffer?
    var tensorBufferId: Int = 1
    
    override required init(name: String, vertices: [V], device: MTLDevice) {
        super.init(name: name, vertices: vertices, device: device)
    }
    
    func getVertex(id: Int) -> Vertexable {
        return V(chunks: [float4(1.0, 1.0, 1.0, 1.0)])
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        //write vertexbuffer
        //write tensorbuffer
    }
}

// TODO: here, i'm referring to a mesh as a kind of 3D lattice with no interior
// - this will likely not be tensorable, as i don't think i can handle propagating information
//   through a 3D object right now.
//class Mesh<N: protocol<Vertexable, Chunkable>>: Node<N>, Lattice, RenderEncodable {
//    
//    func encode(renderEncoder: MTLRenderCommandEncoder) {
//
//    }
//}

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

// TODO: split off some functionility into MeshGenerator

// L = Lattice Type
class LatticeGenerator<L: Lattice, N: Modelable>: ComputeGenerator {
    var node: N?
    
    override init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        computeFunctionName = "lattice_generator_function"
    }
    
    // can be initialized given
    //  - a set of vertices
    //  - or another lattice of the same dimensionality
    
    func generateLattice(node: Modelable) -> L {
        //override in subclass
        return L(name: "Lattice", vertices: [], device: self.device)
    }
}

class BisectionLatticeGenerator<L: Lattice, N: Modelable>: LatticeGenerator<L, N> {
    
    override init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        computeFunctionName = "generateBisectionLattice"
    }
    
    // add numIterations to params?
    override func generateLattice(node: Modelable) -> L {
        // assume 6 points input, if a base node
        // read in each triangle
        // convert it into 4 triangles
        
        //override in subclass
        return L(name: "Lattice", vertices: [], device: self.device)
    }
    
}

// hmm how to make this work for both texture and color
//struct QuadInStruct<V: protocol<Vertexable, Chunkable>> {
//    
//}

//generates a rectangular lattice, composed of triangle pairs
class QuadLatticeGenerator<L: Lattice, N: Modelable>: LatticeGenerator<L, N> {
    var quadInBuffer: MTLBuffer?
    var quadInBufferId = 0
    var quadInBufferLabel = "quad lattice vertices in"
    var quadLatticeConfigBuffer: MTLBuffer?
    var quadLatticeConfigBufferId = 2
    var quadLatticeConfigBufferLabel = "quad lattice config in"
    var triangleOutBuffer: MTLBuffer?
    var triangleOutBufferId = 1
    var triangleOutBufferLabel = "quad lattice triangles out"
    
    override init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        computeFunctionName = "quadLatticeGenerator"
    }
    
    override func generateLattice(node: Modelable) -> L {
        // create output buffer of zeros
        // create input buffer
        // set compute buffers
        
        return L(name: "Lattice", vertices: [], device: self.device)
    }
    
    override func prepareBuffers() {
        
    }
    
//    func prepareQuadInBuffer() {
//        quadInBuffer = device.newBufferWithLength(
//    }
//    
    func prepareQuadLatticeBuffer() {
        
    }
    
    func prepareTriangleOutBuffer() {
        
    }
}


// generates a uniform lattice composed of equilateral triangles
// - where every node is equidistant
class HexLatticeGenerator<L: Lattice, N: Modelable>: LatticeGenerator<L, N> {
    
}

////TODO: takes a textured quad and processes the vertices to result in a list of vertices
//// for triangles and their texture coords
//class TexturedLatticeGenerator {
//    
//}
//