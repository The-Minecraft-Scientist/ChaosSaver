//
//  Renderer.swift
//  ChaosSaver
//
//  Created by Charles Liske on 2/12/23.
//
import Foundation
import Metal
import MetalKit
import simd
import ScreenSaver

let triangles: [simd_float2] = [simd_float2(x: -1, y: -1),
                                simd_float2(x: -1, y: 1),
                                simd_float2(x: 1, y: 1),
                                
                                simd_float2(x: -1, y: -1),
                                simd_float2(x: 1, y: 1),
                                simd_float2(x: 1, y: -1)]

let NUM_POINTS: Int = 5000
let MIN_BOUNDS = simd_float3(-30.0, 0.0, 0.0)
let MAX_BOUNDS = simd_float3(30.0, 0.0, 55)

struct Uniforms {
    var res: simd_uint2
}


extension simd_float3 {
    init(min: simd_float3, max: simd_float3) {
        self.init()
        x = Float.random(in: min.x...max.x)
        y = Float.random(in: min.y...max.y)
        z = Float.random(in: min.z...max.z)
    }
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let mtkView: MTKView
    let vertexDescriptor: MTLVertexDescriptor
    var visualPipeline: MTLRenderPipelineState!
    var updatePipeline: MTLComputePipelineState!
    let commandQueue: MTLCommandQueue
    var pointsBuf, pointsHeaderBuf: MTLBuffer
    let layer: CAMetalLayer
    init(view: MTKView, device: MTLDevice) {
        //View and Device
        self.mtkView = view
        self.device = device
        mtkView.device = device
        // Vertex descriptor
        self.vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride
        //Command Queue
        self.commandQueue = device.makeCommandQueue()!
        //Static Buffers
        var pointsHeaders: [RBHeader] = []
        var points: [simd_float3] = []
        for i in 0...(NUM_POINTS - 1) {
            // Generate storage buffers
            var arr: [simd_float3] = Array(repeating: simd_float3(repeating: 0.0), count: 1000)
            arr[0] = simd_float3(min: MIN_BOUNDS, max: MAX_BOUNDS)
            points.append(contentsOf: arr)
            // Generate ringbuf headers
            let zeroI = 1000 * UInt32(i)
            pointsHeaders.append(RBHeader(buf: nil, last: zeroI + 1, first: zeroI, count: 1000, zeroIndex: zeroI))
        }
        pointsBuf = makePrivateBuffer(
            buf: device.makeBuffer(bytes: points, length: MemoryLayout<simd_float3>.stride * points.count, options: .storageModeShared)!,
            queue: commandQueue
        )
        pointsHeaderBuf = makePrivateBuffer(buf: device.makeBuffer(bytes: pointsHeaders, length: MemoryLayout<RBHeader>.stride * pointsHeaders.count, options: .storageModeShared)!, queue: commandQueue)
        layer = view.currentDrawable!.layer
        super.init()
        
        buildPipelines()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    func draw(in view: MTKView) {
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = layer.nextDrawable() {
            let updateLorentzEncoder = commandBuffer.makeComputeCommandEncoder()!
            updateLorentzEncoder.setComputePipelineState(updatePipeline)
            updateLorentzEncoder.setBuffer(pointsHeaderBuf, offset: 0, index: 0)
            updateLorentzEncoder.setBuffer(pointsBuf, offset: 0, index: 1)
            updateLorentzEncoder.dispatchThreads(MTLSize(width: NUM_POINTS, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            updateLorentzEncoder.endEncoding()
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.setRenderPipelineState(visualPipeline)
            renderEncoder.setVertexBytes(triangles, length: triangles.count * MemoryLayout<simd_float2>.stride, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.setCullMode(.back)
            renderEncoder.setDepthClipMode(.clamp)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
            }
        
    }
    func buildPipelines() {
        let bundle = Bundle(for: Renderer.self)
        guard let library = try? device.makeLibrary(filepath: bundle.bundlePath + "/Contents/Resources/default.metallib") else {
            fatalError("I died")
        }
        let vertexFunction = library.makeFunction(name: "vert_main")
        let fragmentFunction = library.makeFunction(name: "frag_main")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexDescriptor = self.vertexDescriptor
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        do {
            visualPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
        let updateLorentzFunction = library.makeFunction(name: "update_lorentz")
        do {
            updatePipeline = try device.makeComputePipelineState(function: updateLorentzFunction!)
        } catch {
            fatalError("Could not create render pipeline state object: \(error)")
        }
        
    }
}
//helper functions
func makePrivateBuffer(buf: MTLBuffer, queue: MTLCommandQueue) -> MTLBuffer {
    let outbuf = buf.device.makeBuffer(length: buf.length, options: .storageModePrivate)!
    let blit_buffer = queue.makeCommandBuffer()!
    let blit_encoder = blit_buffer.makeBlitCommandEncoder()!
    blit_encoder.copy(from: buf, sourceOffset: 0, to: outbuf, destinationOffset: 0, size: buf.length)
    blit_encoder.endEncoding()
    blit_buffer.addCompletedHandler( {
        (_: MTLCommandBuffer) -> Void in
            buf.setPurgeableState(.empty)
        })
    blit_buffer.commit()
    return outbuf
}
