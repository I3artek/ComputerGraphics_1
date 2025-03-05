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
    // UI things
    @State private var originalImage: NSImage?
    @State private var processedImage: NSImage?
    @State private var defaultImage: NSImage = NSImage()
    @State var showFileImporter = false
    @State private var filters: [FilterWrapper] = []
    // Metal things
    @State private var device: MTLDevice!
    @State private var defaultLibrary: MTLLibrary!
    
    var body: some View {
        HStack {
            VStack {
                VStack {
                    Text("Linear Filters")
                    Button("Inversion") {
                        filters.append(FilterWrapper(filter: LinearFilter(name: "inversion"), description: "Inversion"))
                    }
                    Button("Brightness correction") {
                        filters.append(FilterWrapper(filter: LinearFilter(name: "brightness_correction"), description: "Brightness Correction"))
                    }
                    Button("Contrast Enhancement - TODO") {
                        filters.append(FilterWrapper(filter: LinearFilter(name: "identity"), description: "Identity"))
                    }
                    Button("Gamma correction") {
                        filters.append(FilterWrapper(filter: LinearFilter(name: "gamma_correction"), description: "Gamma Correction"))
                    }
                }
                VStack {
                    Text("Convolutional Filters")
                }
            }
            VStack {
                Text("Filter stack")
                List(filters) { filterWrapper in
                    HStack(spacing: 0) {
                        Text(filterWrapper.description)
                        Spacer()
                        if filterWrapper.filter is ConvolutionFilter {
                            Text("dupa")
                        }
                        Button("Delete", systemImage: "trash", action: {
                            filters.removeAll(where: { $0.id == filterWrapper.id })
                        })
                    }
                }
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
            for filterWrapper in filters {
                let filter = filterWrapper.filter
                if let linearFilter = filter as? LinearFilter {
                    // apply linear filter
                    applyFilter(filterName: linearFilter.name, texture: texture, outTexture: outTexture)
                }
                if let convFilter = filter as? ConvolutionFilter {
                    // apply convolutional filter
                }
                // set the inTexture to the processed one
                texture = outTexture
                // create new texture for writing changes
                outTexture = try loader.newTexture(cgImage: cg, options: textureOptions)
            }
            // swap Red and Blue
            // this step is needed because while creating the MTLTexture, the color data is converted to BGRA automatically
            // but when converting the texture back to an image, it is not, so we need to bring it back to RGBA manually
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
    //TwoImages()
}
