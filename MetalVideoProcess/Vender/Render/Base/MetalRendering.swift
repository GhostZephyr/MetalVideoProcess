import Foundation
import Metal

// OpenGL uses a bottom-left origin while Metal uses a top-left origin.
public let standardImageVertices: [Float] = [-1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0]

extension MTLCommandBuffer {
    func clear(with color: Color, outputTexture: Texture) {
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.redComponent), Double(color.greenComponent), Double(color.blueComponent), Double(color.alphaComponent))
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        debugPrint("Clear color: \(renderPass.colorAttachments[0].clearColor)")
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.endEncoding()
    }
    
    public func computeQuad(pipelineState: MTLComputePipelineState,
                     uniformSettings: ShaderUniformSettings? = nil,
                     inputTextures: [UInt: Texture],
                     outputTexture: Texture,
                     threadGroupCount: MTLSize = MTLSizeMake(16, 16, 1),
                     threadGroups: MTLSize,
                     useNormalizedTextureCoordinates: Bool = true,
                     imageVerticles: [Float] = standardImageVertices,
                     outputOrientation: ImageOrientation = .portrait,
                     device: MetalRenderingDevice = sharedMetalRenderingDevice) {
        guard let commandEncoder = self.makeComputeCommandEncoder() else {
            return
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
        var lastIndex = 0
        for textureIndex in 0..<inputTextures.count {
            let texture = inputTextures[UInt(textureIndex)]
            commandEncoder.setTexture(texture?.texture, index: textureIndex)
            lastIndex = textureIndex
        }
        
        
        commandEncoder.setTexture(outputTexture.texture, index: lastIndex + 1)
        uniformSettings?.restoreShaderSettings(computeEncoder: commandEncoder)
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()
    }
    
    public func renderQuad(pipelineState: MTLRenderPipelineState,
                    uniformSettings: ShaderUniformSettings? = nil,
                    inputTextures: [UInt: Texture],
                    useNormalizedTextureCoordinates: Bool = true,
                    imageVertices: [Float] = standardImageVertices,
                    outputTexture: Texture,
                    outputOrientation: ImageOrientation = .portrait,
                    device: MetalRenderingDevice = sharedMetalRenderingDevice) {
        let vertexBuffer = device.device.makeBuffer(
            bytes: imageVertices,
            length: imageVertices.count * MemoryLayout<Float>.size,
            options: [])!
        vertexBuffer.label = "Vertices"
        
        
        let renderPass = MTLRenderPassDescriptor()
        renderPass.colorAttachments[0].texture = outputTexture.texture
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        renderPass.colorAttachments[0].storeAction = .store
        renderPass.colorAttachments[0].loadAction = .clear
        
        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: renderPass) else {
            fatalError("Could not create render encoder")
        }
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for textureIndex in 0..<inputTextures.count {
            let currentTexture = inputTextures[UInt(textureIndex)]!
            let inputTextureCoordinates = currentTexture.textureCoordinates(for: outputOrientation,
                                                                            normalized: useNormalizedTextureCoordinates)
            let textureBuffer = device.device.makeBuffer(bytes: inputTextureCoordinates,
                                                                             length: inputTextureCoordinates.count * MemoryLayout<Float>.size,
                                                                             options: [])!
            textureBuffer.label = "Texture Coordinates"

            renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1 + textureIndex)
            renderEncoder.setFragmentTexture(currentTexture.texture, index: textureIndex)
        }
        uniformSettings?.restoreShaderSettings(renderEncoder: renderEncoder)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

public func generateComputePipelineState(device: MetalRenderingDevice,
                                  kernelFunctionName: String,
                                  operationName: String) -> (MTLComputePipelineState, [String: (Int, MTLDataType)]) {
    guard let computeFunction = device.shaderLibrary.makeFunction(name: kernelFunctionName) else {
        fatalError("\(operationName): could not compile compute function \(kernelFunctionName)")
    }
           
    let descriptor = MTLComputePipelineDescriptor()
    descriptor.computeFunction = computeFunction
    
    do {
        var reflection: MTLAutoreleasedComputePipelineReflection?
        
        let pipelineState = try device.device.makeComputePipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)
        

        var uniformLookupTable: [String: (Int, MTLDataType)] = [: ]
        if let computeArguments = reflection?.arguments {
            for computeArgument in computeArguments where computeArgument.type == .buffer {
                if
                  (computeArgument.bufferDataType == .struct),
                  let members = computeArgument.bufferStructType?.members.enumerated() {
                    for (index, uniform) in members {
                        uniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        return (pipelineState, uniformLookupTable)
    } catch {
        fatalError("Compute pipeline 创建失败")
    }
    
}

public func generateRenderPipelineState(device: MetalRenderingDevice,
                                 vertexFunctionName: String,
                                 fragmentFunctionName: String,
                                 operationName: String) -> (MTLRenderPipelineState, [String: (Int, MTLDataType)]) {
    guard let vertexFunction = device.shaderLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("\(operationName): could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = device.shaderLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("\(operationName): could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.rasterSampleCount = 1
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    do {
        var reflection: MTLAutoreleasedRenderPipelineReflection?
        let pipelineState = try device.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)

        var uniformLookupTable: [String: (Int, MTLDataType)] = [: ]
        if let fragmentArguments = reflection?.fragmentArguments {
            for fragmentArgument in fragmentArguments where fragmentArgument.type == .buffer {
                if
                  (fragmentArgument.bufferDataType == .struct),
                  let members = fragmentArgument.bufferStructType?.members.enumerated() {
                    for (index, uniform) in members {
                        uniformLookupTable[uniform.name] = (index, uniform.dataType)
                    }
                }
            }
        }
        
        return (pipelineState, uniformLookupTable)
    } catch {
        fatalError("Could not create render pipeline state for vertex: \(vertexFunctionName), fragment: \(fragmentFunctionName), error: \(error)")
    }
}
