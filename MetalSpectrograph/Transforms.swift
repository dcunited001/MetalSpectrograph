//
//  Transforms.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd

class Metal3DTransforms {
    // sx  0   0   0
    // 0   sy  0   0
    // 0   0   sz  0
    // 0   0   0   1
    
    class func scale(x: Float, y: Float, z: Float) -> float4x4 {
        let v: float4 = [x, y, z, 1.0]
        return float4x4(diagonal: v)
    }
    
    class func scale(s: float3) -> float4x4 {
        let v: float4 = [s.x, s.y, s.z, 1.0]
        return float4x4(diagonal: v)
    }
    
    class func scale(s: float4) -> float4x4 {
        return float4x4(diagonal: s)
    }
    
    // 1   0   0   tx
    // 0   1   0   ty
    // 0   0   1   tz
    // 0   0   0   1
    
    class func translate(x: Float, y: Float, z: Float) -> float4x4 {
        return translate(float3(x, y, z))
    }
    
    class func translate(t: float3) -> float4x4 {
        var M = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
        M[3] = [t.x, t.y, t.z, 1.0]
        return M
    }
    
    //alternate implementation
    class func translate(t: float4) -> float4x4 {
        var M = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
        M[3] = t
        return M
    }
    
    static let k1Div180_f: Float = 1.0 / 180.0;
    class func radiansOverPi(degrees: Float) -> Float {
        return (degrees * k1Div180_f)
    }
    
    class func toRadians(val:Float) -> Float {
        return val * Float(M_PI) / 180.0;
    }
    
    class func rotate(r: float4) -> float4x4{
        var a = radiansOverPi(r.w)
        var c:Float = 0.0
        var s:Float = 0.0
        __sincospif(a, &c, &s)
        
        var u = normalize(float3(r.x, r.y, r.z))
        let k = 1.0 - c
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
    
    // w - width
    // h - height
    // d - depth
    // n - near
    
    // w   0   0   0
    // 0   h   0   0
    // 0   0   d   1
    // 0   0   d*n 0
    
    class func frustum(fovH:Float, fovV:Float, near:Float, far:Float) -> float4x4 {
        let width:Float = 1.0 / tan(toRadians(0.5 * fovH))
        let height:Float = 1.0 / tan(toRadians(0.5 * fovV))
        let sDepth:Float = far / (far-near)
        
        var P = float4(0.0)
        var Q = float4(0.0)
        var R = float4(0.0)
        var S = float4(0.0)
        
        P.x = width
        Q.y = height
        R.z = sDepth
        R.w = 1.0
        S.z = -sDepth * near
        
        return float4x4([P,Q,R,S])
    }
    
    class func frustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> float4x4 {
        let width = right - left
        let height = top - bottom
        let depth = far - near
        let sDepth = far / depth
        
        var P = float4(0.0)
        var Q = float4(0.0)
        var R = float4(0.0)
        var S = float4(0.0)
        
        P.x = width
        Q.y = height
        R.z = sDepth
        R.w = 1.0
        S.z = -sDepth * near
        
        return float4x4([P,Q,R,S])
    }
    
    class func frustum_oc(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float) -> float4x4 {
        let sWidth  = 1.0 / (right - left)
        let sHeight = 1.0 / (top - bottom)
        let sDepth  = far / (far - near)
        let dNear   = 2.0 * near
        
        var P = float4(0.0)
        var Q = float4(0.0)
        var R = float4(0.0)
        var S = float4(0.0)
        
        P.x =  dNear * sWidth
        Q.y =  dNear * sHeight
        R.x = -sWidth  * (right + left)
        R.y = -sHeight * (top + bottom)
        R.z =  sDepth
        R.w =  1.0
        S.z = -sDepth * near
        
        return float4x4([P,Q,R,S])
    }
    
    class func perspective(width:Float, height:Float, near:Float, far:Float) -> float4x4 {
        let zNear = 2.0 * near
        let zFar = far / (far - near)
        
        var P = float4(0.0, 0.0, 0.0, 0.0)
        var Q = float4(0.0, 0.0, 0.0, 0.0)
        var R = float4(0.0, 0.0, 0.0, 0.0)
        var S = float4(0.0, 0.0, 0.0, 0.0)
        
        P.x = zNear / width
        Q.y = zNear / height
        R.z = zFar
        R.w = 1.0
        S.z = -near * zFar
        
        return float4x4([P,Q,R,S])
    }
    
    class func perspectiveFov(fovy:Float, aspect:Float, near:Float, far:Float) -> float4x4 {
        let angle:Float = toRadians(0.5 * fovy)
        let yScale:Float = 1.0 / tanf(angle)
        let xScale:Float = yScale / aspect
        let zScale = far / (far - near)
        
        var P = float4(0.0, 0.0, 0.0, 0.0)
        var Q = float4(0.0, 0.0, 0.0, 0.0)
        var R = float4(0.0, 0.0, 0.0, 0.0)
        var S = float4(0.0, 0.0, 0.0, 0.0)
        
        P.x = xScale
        Q.y = yScale
        R.z = zScale
        R.w = 1.0
        S.z = -near * zScale
        
        return float4x4([P, Q, R, S])
    }
//    
//    static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ) {
//    // 1 / tan == cot
//    float yscale = 1.0f / tanf(fovY * 0.5f);
//    float xscale = yscale / aspect;
//    float q = farZ / (farZ - nearZ);
//    
//    matrix_float4x4 m = {
//    .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
//    .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
//    .columns[2] = { 0.0f, 0.0f, q, 1.0f },
//    .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
//    };
//    
//    return m;
//    }
    
    
    class func perspectiveFov(fovy:Float, width:Float, height:Float, near:Float, far:Float) -> float4x4 {
        let aspect:Float = width / height
        return perspectiveFov(fovy, aspect: aspect, near: near, far: far)
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
