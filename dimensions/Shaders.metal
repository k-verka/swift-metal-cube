#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float  alpha;
};

struct Uniforms {
    float4x4 rotationMatrix;
};

vertex VertexOut vertex_main(VertexIn in               [[stage_in]],
                             constant Uniforms& u      [[buffer(1)]],
                             constant float2& cursor   [[buffer(2)]]) {
    VertexOut out;
    float4 pos = float4(in.position, 1.0);
    out.position = u.rotationMatrix * pos;
    out.pointSize = 4.0;

    float2 ndc = out.position.xy / out.position.w;
    float dist = length(ndc - cursor);
    float maxD = 1.0;
    out.alpha = clamp(1.0 - dist / maxD, 0.0, 1.0);

    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(float3(1.0), in.alpha);
}
