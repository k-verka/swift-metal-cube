//
//  Shaders.metal
//  dimensions
//
//  Created by Егор Каверин on 16.07.2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
};

struct Uniforms {
    float4x4 rotationMatrix;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    float4 pos = float4(in.position, 1.0);
    out.position = uniforms.rotationMatrix * pos;
    out.pointSize = 2.0;
    return out;
}

fragment float4 fragment_main() {
    return float4(1, 1, 1, 1); // Красный цвет
}


