//
//  render.metal
//  created by Harri Hilding Smatt on 2026-01-14
//

#include <metal_stdlib>
#include "../inc/types.h"
using namespace metal;

struct share_struct
{
    float4 position [[position]];
    float2 position_rel;
    float3 normal;
    float4 color;
};

vertex share_struct clear_vs(const uint32_t vertex_id [[ vertex_id ]])
{
    share_struct out;
    out.position_rel = float2((vertex_id >> 1), (vertex_id & 1));
    out.position = float4(out.position_rel * 2.0 - 1.0, 0.0, 1.0);
    return out;
}

fragment float4 clear_fs(const share_struct shared [[ stage_in ]],
                         const device float& bg_multiplier [[ buffer(0) ]],
                         const device float& bg_offset [[ buffer(1) ]],
                         const texture2d<float> tx [[ texture(0) ]],
                         const texture2d<float> bg [[ texture(1) ]])
{
    constexpr sampler tx_sampler(mag_filter::nearest, min_filter::nearest);
    const float3 tex = tx.sample(tx_sampler, float2(sqrt(tan(shared.position_rel.x)+bg_offset),
                                                    sqrt(atan(shared.position_rel.y)+bg_offset))).rgb;
    const float3 tex_bg = bg.sample(tx_sampler, float2(abs(sin(shared.position_rel.y + shared.position_rel.x + bg_multiplier * 0.01)),
                                                       shared.position_rel.y)).rgb;
    return saturate(float4(tex_bg * (0.2 * bg_multiplier) + tex * bg_multiplier, 0.1));
}

vertex share_struct copy_vs(const uint32_t vertex_id [[ vertex_id ]])
{
    share_struct out;
    out.position_rel = float2((vertex_id >> 1), (vertex_id & 1));
    out.position = float4(float2(0.0 + out.position_rel.x, 1.0 - out.position_rel.y) * 2.0 - 1.0, 0.0, 1.0);
    return out;
}

fragment float4 copy_fs(const share_struct shared [[ stage_in ]],
                        const texture2d<float> tx [[ texture(0) ]],
                        const depth2d<float> dp [[ texture(1) ]])
{
    constexpr sampler texture_sampler(mag_filter::bicubic, min_filter::bicubic);
    
    const float tex_mul = 1.0;
    const float2 tex_pos = shared.position_rel;
    const float dp_val = dp.sample(texture_sampler, shared.position_rel);
    const float4 tx_col = tx.sample(texture_sampler, tex_pos);
    return float4(pow(dp_val, 4.0) * tx_col.rgb * saturate(0.5 + 0.5 * sqrt(tex_mul)), 1.0);
}

vertex share_struct wireframe_cube_vs(const device MVPStruct& mvp [[ buffer(0) ]],
                                      const device float4& col [[ buffer(1) ]],
                                      const uint32_t vertex_id [[ vertex_id ]],
                                      const uint32_t instance_id [[ instance_id ]])
{
    const uint i_0 = (instance_id >> 1) & 1;
    const uint i_1 = (((instance_id + 1) >> 1) & 1);
    const uint v_0 = (vertex_id >> 1) & 1;
    const uint v_1 = ((vertex_id + 1) >> 1) & 1;
    const uint i_1_v_1 = !i_1 ^ v_1;
    const float3 pos = float3( int3(i_1_v_1, v_0, i_1) & (i_0 ^ 1) |
                               int3(i_1, v_0 ^ 1, i_1_v_1 ^ 1) & i_0 );
       
    share_struct out;
    out.position = mvp.proj * mvp.view *
                    (float4(1.0, 1.0, 0.01, 1.0) *
                     (mvp.model * float4(pos * 2.0 - 1.0, 1.0)));
    out.color = col;
    return out;
}

fragment float4 wireframe_cube_fs(const share_struct shared [[ stage_in ]])
{
    return saturate(shared.color);
}

vertex share_struct filled_cube_vs(const device MVPStruct& mvp [[ buffer(0) ]],
                                   const device float4& col [[ buffer(1) ]],
                                   const uint32_t vertex_id [[ vertex_id ]],
                                   const uint32_t instance_id [[ instance_id ]])
{
    const float3 pos = float3( int3((vertex_id >> 1) & 0x01, 1 - (vertex_id & 0x01), 0.0) );
    
    const float3 nrm = float3( int3( 0, 0, 1) );
    
    share_struct out;
    out.position = mvp.proj * mvp.view *
                    (float4(1.0, 1.0, 0.01, 1.0) *
                     (mvp.model * float4(pos * 2.0 - 1.0, 1.0)));
    out.position_rel = pos.xy;
    out.normal = float3x3( mvp.model[0].xyz,
                           mvp.model[1].xyz,
                           mvp.model[2].xyz ) * nrm;
    out.color = col;
    return out;
}

fragment float4 filled_cube_fs(const share_struct shared [[ stage_in ]])
{
    const float k = saturate(pow(float(int(shared.position_rel.x * 10) ^ !int(shared.position_rel.y * 10)) / 10.0, 2.0));
    const float3 d3 = saturate(normalize(pow(abs(shared.position.xyz), abs(shared.normal))));
    return saturate(float4(
        shared.color.rgb * step(normalize(cross(shared.normal, shared.position.xyz)) * sqrt(d3),
            normalize(shared.position.xyz / shared.position.w)), k));
}
