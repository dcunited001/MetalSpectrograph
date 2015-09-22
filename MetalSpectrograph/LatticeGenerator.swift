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

// TODO: explore delegates for the design of these classes

protocol Lattice {
    typealias VertexType: Vertexable, Chunkable
    
    var lattice: Modelable? { get set }
//    var adjacentNodeCount: { get set }
    var tensorBuffer: MTLBuffer? { get set }
    var tensorBufferId: Int { get set }
    func getVertex(id: Int) -> Vertexable
    
    // define method for generating lattice points
//    func generateLattice(node: Modelable)
    
    // define tensors for updating the lattice

    // write to buffer
    
    init(name: String, vertices: [VertexType], device: MTLDevice)
    init(device: MTLDevice, name: String, vertexPtr: UnsafeMutablePointer<Void>, length: Int)
}

class Lattice2D<V: protocol<Vertexable, Chunkable>>: Node<V>, Lattice, RenderEncodable, Rotatable, Translatable, Scalable {
    
    var rotationRate: Float = 20.0
    var updateRotationalVectorRate: Float = 0.5
    var translationRate: Float = 0.5
    var scaleRate: Float = 0.25
    typealias VertexType = V
    
    var lattice: Modelable?
    var tensorBuffer: MTLBuffer?
    var tensorBufferId: Int = 1
    
    override required init(name: String, vertices: [V], device: MTLDevice) {
        super.init(name: name, vertices: vertices, device: device)
    }
    
    convenience required init(device: MTLDevice, name: String, vertexPtr: UnsafeMutablePointer<Void>, length: Int) {
        self.init(name: name, vertices: [], device: device)
        
        self.vCount = length
        self.vBytes = Node<V>.calculateBytes(length)
        self.vertexBuffer = self.device.newBufferWithBytes(vertexPtr, length: vBytes, options: .CPUCacheModeDefaultCache)
        
        print(self.vCount)
        print(self.vBytes)
        
        updateModelMatrix()
    }
    
    func getVertex(id: Int) -> Vertexable {
        return V(chunks: [float4(1.0, 1.0, 1.0, 1.0)])
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: vertexBufferId)
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
class LatticeGenerator<L: protocol<Modelable, Lattice>, N: protocol<Modelable, VertexBufferable>>: ComputeGenerator {
    var node: N?
    
    override init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        computeFunctionName = "lattice_generator_function"
    }
    
    // can be initialized given
    //  - a set of vertices
    //  - or another lattice of the same dimensionality
    
    func generateLattice(node: N) -> L {
        //override in subclass
        return L(name: "Lattice", vertices: [], device: self.device)
    }
}

class BisectionLatticeGenerator<L: protocol<Modelable, Lattice>, N: protocol<Modelable, VertexBufferable>>: LatticeGenerator<L, N> {
    
    override init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        computeFunctionName = "generateBisectionLattice"
    }
    
    // add numIterations to params?
    override func generateLattice(node: N) -> L {
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

struct QuadLatticeConfig {
    var sizeX: Int
    var sizeY: Int
}

//generates a rectangular lattice, composed of triangle pairs
class QuadLatticeGenerator<L: protocol<Modelable, Lattice>, N: protocol<RenderEncodable,Modelable,VertexBufferable>>: LatticeGenerator<L, N> {
    typealias LatticeVertexType = L.VertexType
    
    var quadInBuffer: MTLBuffer?
    var quadInVertices: [Vertexable]?
    var quadInPtr: UnsafeMutablePointer<Void>?
    var quadInBufferId = 0
    var quadInBufferLabel = "quad lattice vertices in"
    var quadLatticeConfig: QuadLatticeConfig
    var quadLatticeConfigBuffer: MTLBuffer?
    var quadLatticeConfigBufferId = 2
    var quadLatticeConfigBufferLabel = "quad lattice config in"
    var trianglePtr: UnsafeMutablePointer<L.VertexType>?
    var triangleBufferPtr: UnsafeMutableBufferPointer<L.VertexType>?
    var triangleOutPtr: UnsafeMutablePointer<Void>?
    var triangleOutBuffer: MTLBuffer?
    var triangleOutBufferId = 1
    var triangleOutBufferLabel = "quad lattice triangles out"
    var numTriangles: Int?
    
    var triangleOut: [LatticeVertexType] = []
    
    override init(device: MTLDevice, size: CGSize) {
        quadLatticeConfig = QuadLatticeConfig(sizeX: Int(size.width), sizeY: Int(size.height))
        super.init(device: device, size: size)
        computeFunctionName = "quadLatticeGenerator"
    }
    
    override func generateLattice(node: N) -> L {
        numTriangles = Int(size.width * size.height)
        
        prepareTriangleOutBuffer(node)
        quadInVertices = node.getRawVertices()
        print(node.getRawVertices())
        
        let commandBuffer = commandQueue.commandBuffer()
        execute(commandBuffer)
        
        //retrieve command buffer
        //execute()  // encodes

//        let dispatchSemaphore: dispatch_semaphore_t = avaliableResourcesSemaphore
//        
//        commandBuffer.addCompletedHandler { (cmdBuffer) in
//            dispatch_semaphore_signal(dispatchSemaphore)
//        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        triangleOut = [LatticeVertexType](count: numTriangles! * 3, repeatedValue: LatticeVertexType(chunks: [float4(0.0,0.0,0.0,0.0), float4(0.0,0.0,0.0,0.0)]))
        
        // get output data from metal/gpu into swift
        let sizeVertices = numTriangles! * 3 * sizeof(L.VertexType.self)
        print("Num Vertices: \(sizeVertices)")
        let data = NSData(bytesNoCopy: triangleOutPtr!, length: sizeVertices, freeWhenDone: false)
        data.getBytes(&triangleOut, length: sizeVertices)
        
        print(triangleOut)
        
        var triangleOutOpaquePtr = COpaquePointer(triangleOutPtr!)
        trianglePtr = UnsafeMutablePointer<L.VertexType>(triangleOutOpaquePtr)
        triangleBufferPtr = UnsafeMutableBufferPointer(start: trianglePtr!, count: numTriangles!)
        
//        for index in triangleBufferPtr!.startIndex ..< triangleBufferPtr!.endIndex
////            (triangleBufferPtr!.startIndex + 5)
//        {
//            print(triangleBufferPtr![index])
//        }
        
        var generatedLattice = L(device: device, name: "Lattice", vertexPtr: triangleOutPtr!, length: 3 * numTriangles!)
        generatedLattice.modelPosition = node.modelPosition
        generatedLattice.modelRotation = node.modelRotation
        generatedLattice.modelScale = node.modelScale
        generatedLattice.updateModelMatrix()

        return generatedLattice

//        init(device: MTLDevice, name: String, vertexPtr: UnsafeMutablePointer<Void>, length: Int) {
//        return L(name: "Lattice", vertices: triangleBufferPtr!, device: self.device)
    }
    
    override func prepareBuffers() {
        prepareQuadInBuffer()
        prepareQuadLatticeConfigBuffer()
    }
    
    func prepareQuadInBuffer() {
        quadInBuffer = device.newBufferWithLength(4 * N.getVertexSize(), options: .CPUCacheModeDefaultCache)
        quadInBuffer!.label = quadInBufferLabel
        quadInPtr = quadInBuffer!.contents()
        print(quadInPtr!.memory)
    }
    
    func prepareQuadLatticeConfigBuffer() {
        quadLatticeConfigBuffer = device.newBufferWithBytes(&quadLatticeConfig, length: sizeof(QuadLatticeConfig), options: .CPUCacheModeDefaultCache)
        quadLatticeConfigBuffer!.label = quadLatticeConfigBufferLabel
    }
    
    func prepareTriangleOutBuffer(node: N) {
        
        //TODO: refreshTriangleOutBuffer to free/allocate a new buffer size
        let triangleSize = 3 * node.getVertexSize()
        triangleOutBuffer = device.newBufferWithLength(2 * quadLatticeConfig.sizeX * quadLatticeConfig.sizeY * triangleSize, options: .StorageModeShared)
        triangleOutBuffer!.label = triangleOutBufferLabel
        triangleOutPtr = triangleOutBuffer!.contents()
        memset(triangleOutPtr!, 0, triangleSize)
    }
    
    override func encode(computeEncoder: MTLComputeCommandEncoder) {
        // TODO: move node.getRawVertices() to static method?
//        print(quadInVertices)
//        print(sizeof(float4))
//        print("Vertex Size: \(N.getVertexSize())")
//        print(4 * N.getVertexSize())
        memcpy(quadInPtr!, &quadInVertices!, 4 * N.getVertexSize())
        computeEncoder.setBuffer(quadInBuffer, offset: 0, atIndex: quadInBufferId)
        computeEncoder.setBuffer(triangleOutBuffer!, offset: 0, atIndex: triangleOutBufferId)
        computeEncoder.setBuffer(quadLatticeConfigBuffer!, offset: 0, atIndex: quadLatticeConfigBufferId)
    }
    
    func getQuadTriangleSize(node: N) -> Int {
        return node.getVertexSize()
    }
    
    override func getThreadsPerThreadgroup(threadExecutionWidth: Int) -> MTLSize {
        return MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
    }
    
    override func getThreadgroupsPerGrid(threadExecutionWidth: Int) -> MTLSize {
        //TODO: increase threads per threadgroup to cover the remainder!
        return MTLSize(width: (numTriangles! + threadExecutionWidth) / threadExecutionWidth, height: 1, depth: 1)
    }
}

// generates a uniform lattice composed of equilateral triangles
// - where every node is equidistant
class HexLatticeGenerator<L: protocol<Modelable, Lattice>, N: protocol<Modelable, VertexBufferable>>: LatticeGenerator<L, N> {
    
}

////TODO: takes a textured quad and processes the vertices to result in a list of vertices
//// for triangles and their texture coords
//class TexturedLatticeGenerator {
//    
//}
//
