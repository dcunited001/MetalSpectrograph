Metal Spectrograph
==================

### To Do:

TODO: check the quad lattice

TODO: figure out how to modularize the shader files and functions, esp
  to handle mutliple vertex types

TODO: image processing camera input

TODO: rewrite nodes to run in chunks? avoids triangle draw max

TODO: find cause of triangle draw max problem

TODO: rewrite and, for all vertex/compute shaders, destructure all
vertex input.  pass vertices as float4 only, and simply maintain
indexing between the various texture/color/tensor data.

TODO: explore much more functional rewrite with composition and
collections

TODO: MTLRenderPipelineReflection

TODO: fragment shader where color is distance to point

TODO: vertex shader where position is modified by distance to point

TODO: repetitive image quad shader

TODO: repetitive color triangle shader, where color is changed by impact
of adjacent cells

TODO: compute functions with pointers.  write maps 4 the triangle to row/col
& 1D and index on other

TODO: vertex/fragment shaders that stream stereo data into opposite
sides of the visualization

### Math ideas:

- update quad lattice generator to just reference triangles?
- random quad lattice generator (or from triangle) where a random set of 
  vertices from within original surfaces is triangluted
  - triangles can either overlap or can share vertices, but probably
    cooler with shared vertices
  - algorithm to identify the closest vertices on the mesh 
    - maybe that one algorithm, the one with the circles and parabolas and whatnot
    - and can that algorithm be extended to 3D by using spheres?
- coordinate systems for various topological surfaces or whatever:
  torus, concave shapes.
  - properties of these mappings of 2D/3D surface coordinates to 3D 
- spiral coordinate system? theta = angle in radians, r = orthogonal distance from spiral
- polygon tesselation oriented towards a central point or using the
  curvature of the polygon
- spherical indexing for points (grids of spheres of various sizes)
- distort perspective of multiple objects using audio (and groups of
  objects)

