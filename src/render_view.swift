//
//  render_view.swift
//  created by Harri Hilding Smatt on 2026-01-14
//

import MetalKit
import SwiftUI

struct RenderView : NSViewRepresentable {
    let coordinator : Coordinator!
    let view : MTKView!
    
    init() {
        coordinator = Coordinator()
        view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = coordinator
    }

    func makeCoordinator() -> Coordinator {
        return coordinator!
    }

    func makeNSView(context: Context) -> MTKView {
        return view
    }

    func updateNSView(_ uiView: MTKView, context: Context) {
    }

    class Coordinator : NSObject, MTKViewDelegate {
        var metalDevice : MTLDevice!
        var metalCommandQueue : MTLCommandQueue!

        var metalRenderClearPipelineState: MTLRenderPipelineState!
        var metalRenderCopyPipelineState: MTLRenderPipelineState!
        var metalRenderWireframeCubePipelineState: MTLRenderPipelineState!
        var metalRenderFilledCubePipelineState: MTLRenderPipelineState!

        var metalBgTexture: MTLTexture!
        var metalDepthTexture: MTLTexture!
        var metalRenderTexture: MTLTexture!
        
        var metalDepthStencilState: MTLDepthStencilState!

        var rotate_x: Float = 0.0
        var rotate_y: Float = 0.0

        var bg_multiplier : Float = 0.0
        var bg_offset : Float = 0.0

        override init() {
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }

            self.metalCommandQueue = metalDevice.makeCommandQueue()
            let metalLibrary = metalDevice.makeDefaultLibrary()!;

            do {
                let renderClearDescriptor = MTLRenderPipelineDescriptor()
                renderClearDescriptor.vertexFunction = metalLibrary.makeFunction(name: "clear_vs")
                renderClearDescriptor.fragmentFunction = metalLibrary.makeFunction(name: "clear_fs")
                renderClearDescriptor.depthAttachmentPixelFormat = .depth32Float
                renderClearDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
                renderClearDescriptor.colorAttachments[0].isBlendingEnabled = true
                renderClearDescriptor.colorAttachments[0].alphaBlendOperation = .unspecialized
                renderClearDescriptor.colorAttachments[0].rgbBlendOperation = .add
                renderClearDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .unspecialized
                renderClearDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                renderClearDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .unspecialized
                renderClearDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                self.metalRenderClearPipelineState = try metalDevice.makeRenderPipelineState(descriptor: renderClearDescriptor)

                let renderCopyDescriptor = MTLRenderPipelineDescriptor()
                renderCopyDescriptor.vertexFunction = metalLibrary.makeFunction(name: "copy_vs")
                renderCopyDescriptor.fragmentFunction = metalLibrary.makeFunction(name: "copy_fs")
                renderCopyDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                self.metalRenderCopyPipelineState = try metalDevice.makeRenderPipelineState(descriptor: renderCopyDescriptor)
                
                let renderWireframeCubeDescriptor = MTLRenderPipelineDescriptor()
                renderWireframeCubeDescriptor.vertexFunction = metalLibrary.makeFunction(name: "wireframe_cube_vs")
                renderWireframeCubeDescriptor.fragmentFunction = metalLibrary.makeFunction(name: "wireframe_cube_fs")
                renderWireframeCubeDescriptor.depthAttachmentPixelFormat = .depth32Float
                renderWireframeCubeDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
                renderWireframeCubeDescriptor.colorAttachments[0].isBlendingEnabled = true
                renderWireframeCubeDescriptor.colorAttachments[0].alphaBlendOperation = .unspecialized
                renderWireframeCubeDescriptor.colorAttachments[0].rgbBlendOperation = .add
                renderWireframeCubeDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .unspecialized
                renderWireframeCubeDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                renderWireframeCubeDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .unspecialized
                renderWireframeCubeDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                self.metalRenderWireframeCubePipelineState = try metalDevice.makeRenderPipelineState(descriptor: renderWireframeCubeDescriptor)

                let renderFilledCubeDescriptor = MTLRenderPipelineDescriptor()
                renderFilledCubeDescriptor.vertexFunction = metalLibrary.makeFunction(name: "filled_cube_vs")
                renderFilledCubeDescriptor.fragmentFunction = metalLibrary.makeFunction(name: "filled_cube_fs")
                renderFilledCubeDescriptor.depthAttachmentPixelFormat = .depth32Float
                renderFilledCubeDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
                renderFilledCubeDescriptor.colorAttachments[0].isBlendingEnabled = true
                renderFilledCubeDescriptor.colorAttachments[0].alphaBlendOperation = .unspecialized
                renderFilledCubeDescriptor.colorAttachments[0].rgbBlendOperation = .add
                renderFilledCubeDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .unspecialized
                renderFilledCubeDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                renderFilledCubeDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .unspecialized
                renderFilledCubeDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                self.metalRenderFilledCubePipelineState = try metalDevice.makeRenderPipelineState(descriptor: renderFilledCubeDescriptor)

                let metalTextureLoader = MTKTextureLoader(device: metalDevice)
                let imageBgUrl = Bundle.main.url(forResource: "brainsugar_bg", withExtension: "jpg")!
                self.metalBgTexture = try metalTextureLoader.newTexture(URL: imageBgUrl, options: nil)

                let renderDepthDescriptor = MTLTextureDescriptor()
                renderDepthDescriptor.width = 800
                renderDepthDescriptor.height = 800
                renderDepthDescriptor.depth = 1
                renderDepthDescriptor.pixelFormat = .depth32Float
                renderDepthDescriptor.usage = [.shaderRead, .renderTarget]
                renderDepthDescriptor.storageMode = .private
                renderDepthDescriptor.mipmapLevelCount = 1
                self.metalDepthTexture = metalDevice.makeTexture(descriptor: renderDepthDescriptor)

                let renderTextureDescriptor = MTLTextureDescriptor()
                renderTextureDescriptor.width = 800
                renderTextureDescriptor.height = 800
                renderTextureDescriptor.depth = 1
                renderTextureDescriptor.pixelFormat = .rgba16Float
                renderTextureDescriptor.usage = [.shaderRead, .renderTarget]
                renderTextureDescriptor.storageMode = .private
                renderTextureDescriptor.mipmapLevelCount = 1
                self.metalRenderTexture = metalDevice.makeTexture(descriptor: renderTextureDescriptor)
                
                let renderDepthStencilDescriptor = MTLDepthStencilDescriptor()
                renderDepthStencilDescriptor.depthCompareFunction = .less
                renderDepthStencilDescriptor.isDepthWriteEnabled = true
                self.metalDepthStencilState = metalDevice.makeDepthStencilState(descriptor: renderDepthStencilDescriptor)
            } catch let error {
                print(error.localizedDescription)
            }

            super.init()
        }

        func mtkView(_ view : MTKView, drawableSizeWillChange size : CGSize) {
        }
        
        func matrix4x4_perspective_projection(inAspect: Float, inFovRAD: Float, inNear: Float, inFar: Float) -> matrix_float4x4 {
            let y = 1.0 / tan(inFovRAD * 0.5)
            let x = y / inAspect
            let z = inFar / (inFar - inNear)
            
            let X = simd_make_float4(x, 0.0, 0.0,             0.0)
            let Y = simd_make_float4(0.0, y, 0.0,             0.0)
            let Z = simd_make_float4(0.0, 0.0, z,             1.0)
            let W = simd_make_float4(0.0, 0.0, z * -inNear,   0.0)
            
            return matrix_float4x4([X, Y, Z, W])
        }
        
        func matrix4x4_look_at(pos: simd_float3, to: simd_float3, up: simd_float3) -> matrix_float4x4 {
            let z_axis = simd_normalize(to - pos)
            let x_axis = simd_normalize(simd_cross(up, z_axis))
            let y_axis = simd_cross(z_axis, x_axis)
            let t = simd_make_float3(-simd_dot(x_axis, pos), -simd_dot(y_axis, pos), -simd_dot(z_axis, pos))

            return matrix_float4x4([simd_make_float4(x_axis.x, y_axis.x, z_axis.x, 0.0),
                                    simd_make_float4(x_axis.y, y_axis.y, z_axis.y, 0.0),
                                    simd_make_float4(x_axis.z, y_axis.z, z_axis.z, 0.0),
                                    simd_make_float4(t.x,      t.y,      t.z,      1.0)])
        }

        func matrix4x4_rotate_x(_ inAngle: Float) -> matrix_float4x4 {
            let theta = inAngle * .pi / 180.0;
            let sinTheta = sin(theta);
            let cosTheta = cos(theta);
            
            return matrix_float4x4([simd_make_float4( 1.0,      0.0,       0.0, 0.0),
                                    simd_make_float4( 0.0, cosTheta, -sinTheta, 0.0),
                                    simd_make_float4( 0.0, sinTheta,  cosTheta, 0.0),
                                    simd_make_float4( 0.0,      0.0,       0.0, 1.0)])
        }

        func matrix4x4_rotate_y(_ inAngle: Float) -> matrix_float4x4 {
            let theta = inAngle * .pi / 180.0;
            let sinTheta = sin(theta);
            let cosTheta = cos(theta);
            
            return matrix_float4x4([simd_make_float4( cosTheta, 0.0, sinTheta, 0.0),
                                    simd_make_float4(      0.0, 1.0,      0.0, 0.0),
                                    simd_make_float4(-sinTheta, 0.0, cosTheta, 0.0),
                                    simd_make_float4(      0.0, 0.0,      0.0, 1.0)])
        }
        
        func matrix4x4_rotate_z(_ inAngle: Float) -> matrix_float4x4 {
            let theta = inAngle * .pi / 180.0;
            let sinTheta = sin(theta);
            let cosTheta = cos(theta);
            
            return matrix_float4x4([simd_make_float4( cosTheta,-sinTheta, 0.0, 0.0),
                                    simd_make_float4( sinTheta, cosTheta, 0.0, 0.0),
                                    simd_make_float4(      0.0,      0.0, 1.0, 0.0),
                                    simd_make_float4(      0.0,      0.0, 0.0, 1.0)])
        }
        
        func setAudioRmsValue(_ rms: uint8) {
            bg_multiplier = Float(rms) / 3.0
            bg_offset += 1.0 * ((Float(rms) - 1.0) / 3.0)
            if bg_offset >= 20.0 { bg_offset = -20.0 }
            if bg_offset <= -20.0 { bg_offset = 20.0 }
        }

        func draw(in view : MTKView) {
            guard let drawable = view.currentDrawable else {
                return
            }
            let commandBuffer = metalCommandQueue.makeCommandBuffer()

            // render
            if true {
                rotate_x = (rotate_x + Float.random(in: 0.0...(0.25 + bg_multiplier * 0.5))).truncatingRemainder(dividingBy: 360.0)
                rotate_y = (rotate_y + Float.random(in: 0.0...(0.25 + bg_multiplier * 0.75))).truncatingRemainder(dividingBy: 360.0)
                
                var mvp : MVPStruct = MVPStruct();
                mvp.model = matrix4x4_rotate_y(rotate_y) * matrix4x4_rotate_x(rotate_x)
                mvp.view = matrix4x4_look_at(pos: simd_make_float3(0.0, 0.0, 18.0), to: simd_make_float3(0.0, 0.0, 0.0), up: simd_make_float3(0.0, 1.0, 0.0))
                mvp.proj = matrix4x4_perspective_projection(inAspect: 800.0 / 800.0, inFovRAD: 15.0 * (.pi / 180.0), inNear: 1.0, inFar: 50.0)
                
                let renderClearPassDescriptor = MTLRenderPassDescriptor()
                renderClearPassDescriptor.depthAttachment.texture = metalDepthTexture
                renderClearPassDescriptor.depthAttachment.clearDepth = 1.0
                renderClearPassDescriptor.depthAttachment.loadAction = .clear
                renderClearPassDescriptor.depthAttachment.storeAction = .store
                renderClearPassDescriptor.colorAttachments[0].texture = metalRenderTexture
                renderClearPassDescriptor.colorAttachments[0].loadAction =  .load
                renderClearPassDescriptor.colorAttachments[0].storeAction = .store
                
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.depthAttachment.texture = metalDepthTexture
                renderPassDescriptor.depthAttachment.loadAction = .load
                renderPassDescriptor.depthAttachment.storeAction = .store
                renderPassDescriptor.colorAttachments[0].texture = metalRenderTexture
                renderPassDescriptor.colorAttachments[0].loadAction =  .load
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                
                let renderClearCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderClearPassDescriptor)!
                renderClearCommandEncoder.setRenderPipelineState(metalRenderClearPipelineState)
                renderClearCommandEncoder.setCullMode(.none)
                renderClearCommandEncoder.setFragmentBytes(&bg_multiplier, length: MemoryLayout<Float>.size, index: 0)
                renderClearCommandEncoder.setFragmentBytes(&bg_offset, length: MemoryLayout<Float>.size, index: 1)
                renderClearCommandEncoder.setFragmentTexture(metalRenderTexture, index: 0)
                renderClearCommandEncoder.setFragmentTexture(metalBgTexture, index: 1)
                renderClearCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
                renderClearCommandEncoder.endEncoding()
                
                var cube_color = simd_make_float4(1.0, 1.0, 1.0, 1.0)

                let renderWireframeCubeCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                renderWireframeCubeCommandEncoder.setRenderPipelineState(metalRenderWireframeCubePipelineState)
                renderWireframeCubeCommandEncoder.setCullMode(.none)
                renderWireframeCubeCommandEncoder.setDepthStencilState(metalDepthStencilState)
                renderWireframeCubeCommandEncoder.setVertexBytes(&mvp, length: MemoryLayout<MVPStruct>.size, index: 0)
                renderWireframeCubeCommandEncoder.setVertexBytes(&cube_color, length: MemoryLayout<simd_float4>.size, index: 1)
                renderWireframeCubeCommandEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 4, instanceCount: 4)
                renderWireframeCubeCommandEncoder.endEncoding()
                
                let renderFilledCubeCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                renderFilledCubeCommandEncoder.setRenderPipelineState(metalRenderFilledCubePipelineState)
                renderFilledCubeCommandEncoder.setCullMode(.none)
                renderFilledCubeCommandEncoder.setDepthStencilState(metalDepthStencilState)
                renderFilledCubeCommandEncoder.setVertexBytes(&mvp, length: MemoryLayout<MVPStruct>.size, index: 0)
                renderFilledCubeCommandEncoder.setVertexBytes(&cube_color, length: MemoryLayout<simd_float4>.size, index: 1)
                renderFilledCubeCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
                renderFilledCubeCommandEncoder.endEncoding()
                
                //
                // let renderParticlesCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: particlesRenderPassDescriptor)
                // renderParticlesCommandEncoder!.setRenderPipelineState(metalRenderParticlesPipelineState)
                // renderParticlesCommandEncoder!.setCullMode(.none)
                // renderParticlesCommandEncoder!.setVertexBuffer(metalVarsBuffer, offset: 0, index: 0)
                // renderParticlesCommandEncoder!.setVertexBuffer(metalParticleBufferTmp, offset: 0, index: 1)
                // renderParticlesCommandEncoder!.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: renderCount)
                // renderParticlesCommandEncoder!.endEncoding()
                //
                
                let copyPassDescriptor = view.currentRenderPassDescriptor
                copyPassDescriptor!.colorAttachments[0].loadAction = .dontCare
                copyPassDescriptor!.colorAttachments[0].storeAction = .store
                
                let copyCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: copyPassDescriptor!)
                copyCommandEncoder!.setRenderPipelineState(metalRenderCopyPipelineState)
                copyCommandEncoder!.setFragmentTexture(metalRenderTexture, index: 0)
                copyCommandEncoder!.setFragmentTexture(metalDepthTexture, index: 1)
                copyCommandEncoder!.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                copyCommandEncoder!.endEncoding()
            }

            commandBuffer!.present(drawable)
            commandBuffer!.commit()
        }
    }
}
