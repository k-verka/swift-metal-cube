//
//  Matrix4.swift
//  dimensions
//
//  Created by Егор Каверин on 16.07.2025.
//

import Foundation
import simd

typealias Vector3 = SIMD3<Float>
typealias Matrix4 = simd_float4x4

extension Matrix4 {
    static func rotation(angle: Float, axis: Vector3) -> Matrix4 {
        let normalizedAxis = normalize(axis)
        let ct = cos(angle)
        let st = sin(angle)
        let ci = 1 - ct

        let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z

        return Matrix4(columns: (
            SIMD4<Float>(ct + x*x*ci,      x*y*ci - z*st,  x*z*ci + y*st, 0),
            SIMD4<Float>(y*x*ci + z*st,    ct + y*y*ci,    y*z*ci - x*st, 0),
            SIMD4<Float>(z*x*ci - y*st,    z*y*ci + x*st,  ct + z*z*ci,   0),
            SIMD4<Float>(0,                0,              0,             1)
        ))
    }
}
