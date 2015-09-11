//
//  Transforms.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd

class Metal3DTransforms {
//    class func radians(degrees: Float) -> float4x4 {
//
//    }
    
    class func scale(x: Float, y: Float, z: Float) -> float4x4 {
        let v: float4 = [x, y, z, 1.0]
        return float4x4(diagonal: v)
    }
    
    class func scale(s: float3) -> float4x4 {
        let v: float4 = [s.x, s.y, s.z, 1.0]
        return float4x4(diagonal: v)
    }
    
    class func scale(s: float4) -> float4x4 {
        let v: float4 = [s.x, s.y, s.z, 1.0]
        return float4x4(diagonal: v)
    }
    
    class func translate(x: Float, y: Float, z: Float) -> float4x4 {
        return translate(float3(x, y, z))
    }
    
    class func translate(t: float3) -> float4x4 {
        var M = matrix_identity_float4x4
        M.columns.3 = [t.x, t.y, t.z, Float(1.0)]
        return float4x4(M).transpose
    }
    
    static let k1Div180_f: Float = 1.0 / 180.0;
    class func radiansOverPi(degrees: Float) -> Float {
        return (degrees * k1Div180_f)
    }
    
    class func rotate(angle: Float, x: Float, y: Float, z: Float) -> float4x4 {
        let r: float3 = [x, y, z]
        return rotate(angle, r: r)
    }
    
    class func rotate(angle: Float, r: float3) -> float4x4 {
        let a = radiansOverPi(angle)
        var c:Float = 0.0
        var s:Float = 0.0
        
        __sincospif(a, &c, &s)
        
        let k = 1.0 - c
        let u = normalize(r) // unit vector
        let v = s * u
        let w = k * u
        
        let P:float4 = [
            w.x * u.x + c,
            w.x * u.y + v.z,
            w.x * u.z - v.y, 0.0]
        
        let Q:float4 = [
            w.x * u.y - v.z,
            w.y * u.y + c,
            w.y * u.z + v.x, 0.0]
        
        let R:float4 = [
            w.x * u.z + v.y,
            w.y * u.z - v.x,
            w.z * u.z + c, 0.0]

        var S:float4 = [0.0, 0.0, 0.0, 1.0]
        
        return float4x4(rows: [P, Q, R, S])
    }
    
//    simd::float4x4 frustum(const float& fovH,
//    const float& fovV,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 frustum(const float& left,
//    const float& right,
//    const float& bottom,
//    const float& top,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 frustum_oc(const float& left,
//    const float& right,
//    const float& bottom,
//    const float& top,
//    const float& near,
//    const float& far);
    
    class func lookAt(pEye: float4, pCenter: float4, pUp: float4) -> float4x4 {
        let eye:float3 = [pEye[0], pEye[1], pEye[2]]
        let center:float3 = [pCenter[0], pCenter[1], pCenter[2]]
        let up:float3 = [pUp[0], pUp[1], pUp[2]]
        
        return lookAt(eye, center: center, up: up)
    }
    
    class func lookAt(eye: float3, center: float3, up: float3) -> float4x4 {
        let E:float3 = -eye
        let N:float3 = normalize(center + E)
        let U:float3 = normalize(cross(up, N))
        let V:float3 = cross(N, U)
        
        let P:float4 = [U.x, V.x, N.x, 0.0]
        let Q:float4 = [U.y, V.y, N.y, 0.0]
        let R:float4 = [U.z, V.z, N.z, 0.0]
        let S:float4 = [dot(U,E), dot(V,E), dot(N,E), 1.0]
        
        return float4x4(rows: [P, Q, R, S])
    }
    
//    simd::float4x4 perspective(const float& width,
//    const float& height,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 perspective_fov(const float& fovy,
//    const float& aspect,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 perspective_fov(const float& fovy,
//    const float& width,
//    const float& height,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 ortho2d_oc(const float& left,
//    const float& right,
//    const float& bottom,
//    const float& top,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 ortho2d_oc(const simd::float3& origin,
//    const simd::float3& size);
//    
//    simd::float4x4 ortho2d(const float& left,
//    const float& right,
//    const float& bottom,
//    const float& top,
//    const float& near,
//    const float& far);
//    
//    simd::float4x4 ortho2d(const simd::float3& origin,
//    const simd::float3& size);
//
    
}
