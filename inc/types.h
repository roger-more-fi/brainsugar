//
//  types.h
//  created by Harri Hilding Smatt on 2026-01-14
//

#ifndef TYPES_H
#define TYPES_H

#ifdef __METAL_VERSION__
#include <metal_stdlib>
using namespace metal;
#endif

#include <simd/simd.h>

struct MVPStruct {
    simd_float4x4 model;
    simd_float4x4 view;
    simd_float4x4 proj;
};

#endif // TYPES_H
