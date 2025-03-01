//
//  TwoImages.swift
//  ComputerGraphics_1
//
//  Created by I3artek on 01/03/2025.
//
// https://stackoverflow.com/questions/63764637/how-to-open-a-filedialog

import SwiftUI
import Metal
import MetalKit

struct TwoImages: View {
    @State private var originalImage: NSImage?
    @State private var processedImage: NSImage?
    @State private var defaultImage: NSImage = NSImage()
    @State var showFileImporter = false
    
    @State private var device: MTLDevice!
    @State private var defaultLibrary: MTLLibrary!
    
    var body: some View {
        HStack {
            VStack {
                Text("Linear Filters")
            }
            VStack {
                Button("Choose Image") {
                    selectImage()
                }
                .padding()
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: originalImage ?? defaultImage)
                }
                Button("Proccess Image") {
                    doProcessing()
                    //processImage(filterName: "identity")
                }
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: processedImage ?? defaultImage)
                }
            }
            .onAppear {
                setupMetal()
            }
        }
    }
    
    func selectImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.jpeg, .png]
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK, let url = openPanel.url {
            loadImage(from: url)
        }
    }
    
    func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            originalImage = image
        }
        processedImage = originalImage
    }
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()!
        defaultLibrary = device.makeDefaultLibrary()!
    }
    
    func doProcessing() {
        do {
            // create CGImage from NSImage
            guard let cgFirst = originalImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            // we do the following to add alpha channel to images that don't have it
            guard let cg = CIImage(cgImage: cgFirst).cgImage else { return }
            // create textures
            let loader = MTKTextureLoader(device: device)
            let textureOptions: [MTKTextureLoader.Option: Any] = [
                .origin: MTKTextureLoader.Origin.topLeft,
                .SRGB: false,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
            ]
            var texture = try loader.newTexture(cgImage: cg, options: textureOptions)
            var outTexture = try loader.newTexture(cgImage: cg, options: textureOptions)
            // apply filters
            applyFilter(filterName: "identity", texture: texture, outTexture: outTexture)
            texture = outTexture
            outTexture = try loader.newTexture(cgImage: cg, options: textureOptions)
            applyFilter(filterName: "identity", texture: texture, outTexture: outTexture)
            // swap Red and Blue
            texture = outTexture
            outTexture = try loader.newTexture(cgImage: cg, options: textureOptions)
            applyFilter(filterName: "swap_red_blue", texture: texture, outTexture: outTexture)
            // this is needed because
            // convert texture back to CGImage and then NSImage
            let outCG = getCGImage(from: outTexture)
            processedImage = NSImage(cgImage: outCG!, size: NSSize(width: cg.width, height: cg.height))
        } catch {
            print("Error in processing: \(error)")
            return
        }
    }
    
    // this function works for linear filters
    // todo: version for convolutional filters
    func applyFilter(filterName: String, texture: MTLTexture, outTexture: MTLTexture) {
        do {
            let width = Int(originalImage!.size.width)
            let height = Int(originalImage!.size.height)
            guard let commandQueue = device.makeCommandQueue() else { return }
            guard let kernelFunction = defaultLibrary.makeFunction(name: filterName) else { return }
            let pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setTexture(texture, index: 0)
            commandEncoder.setTexture(outTexture, index: 1)
            
            let threadsPerGroup = MTLSizeMake(8, 8, 1)
            let threasPerGrid = MTLSizeMake(width, height, 1)
            commandEncoder.dispatchThreads(threasPerGrid, threadsPerThreadgroup: threadsPerGroup)
            
            commandEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        } catch {
            print("Error applying filter: \(error)")
            return
        }
    }
    
    func processImage(filterName: String) {
        do {
            guard let commandQueue = device.makeCommandQueue() else { return }
            guard let kernelFunction = defaultLibrary.makeFunction(name: filterName) else { return }
            let pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            
            guard let cgFirst = processedImage?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            // we do this to add alpha channel to images that don't have it
            guard let cg = CIImage(cgImage: cgFirst).cgImage else { return }
            
            let loader = MTKTextureLoader(device: device)
            let textureOptions: [MTKTextureLoader.Option: Any] = [
                    .origin: MTKTextureLoader.Origin.topLeft,
                    .SRGB: false
                ]
            let outTextureOptions: [MTKTextureLoader.Option: Any] = [
                    .origin: MTKTextureLoader.Origin.topLeft,
                    .SRGB: false,
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderWrite.rawValue)
                ]
            let texture = try loader.newTexture(cgImage: cg, options: textureOptions)
            let outTexture = try loader.newTexture(cgImage: cg, options: outTextureOptions)
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            commandEncoder.setComputePipelineState(pipelineState)
            commandEncoder.setTexture(texture, index: 0)
            commandEncoder.setTexture(outTexture, index: 1)
            
            let threadsPerGroup = MTLSizeMake(8, 8, 1)
            let threasPerGrid = MTLSizeMake(cg.width, cg.height, 1)
            commandEncoder.dispatchThreads(threasPerGrid, threadsPerThreadgroup: threadsPerGroup)
            
            commandEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            //guard let ncg = outTexture.cgImage else { return }
            //processedImage = outTexture.image
            let outCG = getCGImage(from: outTexture)
            processedImage = NSImage(cgImage: outCG!, size: NSSize(width: cg.width, height: cg.height))
        } catch {
            print("Error loading texture: \(error)")
            return
        }
    }
    
    func getCGImage(from mtlTexture: MTLTexture) -> CGImage? {
        let width = Int(originalImage!.size.width)
        let height = Int(originalImage!.size.height)
        var data = Array<UInt8>(repeatElement(0, count: 4*width*height))
        
        mtlTexture.getBytes(&data,
                            bytesPerRow: 4*width,
                            from: MTLRegionMake2D(0, 0, width, height),
                            mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: &data,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: 4*width,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        return context?.makeImage()
        }
}

#Preview {
    TwoImages()
}
