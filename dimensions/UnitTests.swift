//
//  Test.swift
//  dimensions
//
//  Created by Егор Каверин on 16.07.2025.
//

import Foundation
import simd
//import simd_quaternion
func testVectorOperations() {
    let v1 = Vector3(1, 0, 0)
    let v2 = Vector3(0, 1, 0)
    assert(v1 + v2 == Vector3(1, 1, 0), "Addition failed")
    assert(cross(v1, v2) == Vector3(0, 0, 1), "Cross product failed")
    assert(normalize(Vector3(0, 3, 0)) == Vector3(0, 1, 0), "Normalization failed")
}

func testRotation() {
    let v = Vector3(1, 0, 0)
    let quat = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))
    let rotationMatrix = simd_float4x4(quat)
    let rotated4 = rotationMatrix * SIMD4<Float>(v, 1)
    let rotated = simd_make_float3(rotated4)

    let expected = Vector3(0, 0, -1)

    let epsilon: Float = 0.01
    assert(abs(rotated.x - expected.x) < epsilon, "Rotation X failed")
    assert(abs(rotated.y - expected.y) < epsilon, "Rotation Y failed")
    assert(abs(rotated.z - expected.z) < epsilon, "Rotation Z failed")
}
