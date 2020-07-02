//
//  MetalVideoProcessOperation.swift
//  MetalVideoProcessOperation
//
//  Created by RenZhu Macro on 2020/4/23.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import Metal
import CoreMedia

public func defaultVertexFunctionNameForInputs(_ inputCount: UInt) -> String {
    switch inputCount {
    case 1: 
        return "oneInputVertex"
    case 2: 
        return "twoInputVertex"
    default: 
        return "twoInputVertex"
    }
}


open class MetalVideoProcessOperation: ImageProcessingOperation {
    
    public var debugName: String = ""
    
    deinit {
        debugPrint("deinit: ", self, " targets: ", self.targets.targets)
        self.targets.removeAll()
    }
    
    public var isEnable: Bool = true
    
    public var maximumInputs: UInt
    
    public let targets = TargetContainer() //纹理目标
    public let sources: SourceContainer = SourceContainer() //输入来源
    
    public var activatePassthroughOnNextFrame: Bool = false
    public var uniformSettings: ShaderUniformSettings
    public var useMetalPerformanceShaders: Bool = false {
        didSet {
            if !self.currentDevice.metalPerformanceShadersAreSupported {
                debugPrint("设备不支持")
                useMetalPerformanceShaders = false
            }
        }
    }
    
    /// 时间轴信息，创建FIlter后默认为Zero 则全部纹理接受后都处理，若有值则匹配后处理
    public var timelineRange: CMTimeRange
    public var trackID: Int32 = 0 //默认全部生效
    
    let renderPipelineState: MTLRenderPipelineState
    let operationName: String
    var inputTextures = [UInt: Texture]()
    let textureInputSemaphore = DispatchSemaphore(value: 1)
    var useNormalizedTextureCoordinates = true
    public var metalPerformanceShaderPathway: ((MTLCommandBuffer, [UInt: Texture], Texture) -> ())?
    var currentDevice: MetalRenderingDevice
    
    public func saveUniformSettings(forTimelineRange timeline: CMTimeRange, trackID: Int32) {
        self.timelineRange = timeline
        self.trackID = trackID
    }
    
    /// 初始化一个Filter
    /// - Parameters: 
    ///   - context: 可以指定Context 默认会走Framework中的shader
    ///   - numberOfInputs: 最大输入个数
    ///   - operationName: 操作名，用于调试
    public init(vertexFunctionName: String? = nil, fragmentFunctionName: String,
                numberOfInputs: UInt = 1,
                device: MetalRenderingDevice = sharedMetalRenderingDevice,
                operationName: String = #file) {
        self.currentDevice = device
        self.maximumInputs = numberOfInputs
        self.operationName = operationName
        let concreteVertexFunctionName: String = vertexFunctionName ?? defaultVertexFunctionNameForInputs(numberOfInputs)
        
        let (pipelineState, lookupTable) =
            generateRenderPipelineState(device: device, vertexFunctionName: concreteVertexFunctionName, fragmentFunctionName: fragmentFunctionName, operationName: operationName)
        self.renderPipelineState = pipelineState
        self.timelineRange = .zero
        self.uniformSettings = ShaderUniformSettings(uniformLookupTable: lookupTable, device: self.currentDevice)
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        
    }
    
    public func checkTimelineRange(with texture: Texture) -> (Bool) {
        if self.timelineRange == .zero {
            return true
        } else {
            guard let time = texture.timingStyle.timestamp else {
                let seconds = texture.timingStyle.timestamp!.asCMTime.seconds
                let cmTime = CMTime(seconds: seconds, preferredTimescale: 1)
                
                return self.timelineRange.containsTime(cmTime) ||
                    self.timelineRange.end == cmTime
            }
            
            return self.timelineRange.containsTime(time.asCMTime) || self.timelineRange.end == time.asCMTime
        }
    }
    
    open func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        newTextureWithSize(texture, fromSourceIndex: fromSourceIndex, renderSize: nil, trackID: trackID)
    }
    
    open func newTextureWithSize(_ texture: Texture, fromSourceIndex: UInt, renderSize: CGSize?, trackID: Int32) {
        let rs = self.checkTimelineRange(with: texture)
        if rs == false {
            updateTargetsWithTexture(texture, trackID: trackID)
            return
        } else {
            let distance = CMTime(seconds: texture.frameTime, preferredTimescale: 1000) - self.timelineRange.start
            let progress = distance.seconds / self.timelineRange.duration.seconds
            self.uniformSettings.progress = Float(progress)
        }
        
        self.uniformSettings.iGlobalTime = Float(texture.frameTime)
        
        let _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }
        inputTextures[fromSourceIndex] = texture
        
        if (UInt(inputTextures.count) >= maximumInputs) || activatePassthroughOnNextFrame {
            let outputWidth: Int
            let outputHeight: Int
            
            let firstInputTexture = inputTextures[0]!
            if renderSize != nil {
                if firstInputTexture.orientation.rotationNeeded(for: .portrait).flipsDimensions() {
                    outputWidth = Int(renderSize!.height)
                    outputHeight = Int(renderSize!.width)
                } else {
                    outputWidth = Int(renderSize!.width)
                    outputHeight = Int(renderSize!.height)
                }
            } else {
                if firstInputTexture.orientation.rotationNeeded(for: .portrait).flipsDimensions() {
                    outputWidth = firstInputTexture.texture.height
                    outputHeight = firstInputTexture.texture.width
                } else {
                    outputWidth = firstInputTexture.texture.width
                    outputHeight = firstInputTexture.texture.height
                }
            }
            
            if uniformSettings.usesAspectRatio {
                let outputRotation = firstInputTexture.orientation.rotationNeeded(for: .portrait)
                uniformSettings["aspectRatio"] = firstInputTexture.aspectRatio(for: outputRotation)
            }
            
            guard let commandBuffer = self.currentDevice.commandQueue.makeCommandBuffer() else {return}
            
            let outputTexture = Texture(device: self.currentDevice.device,
                                        orientation: .portrait,
                                        width: outputWidth,
                                        height: outputHeight,
                                        timingStyle: texture.timingStyle)
            
            guard (!activatePassthroughOnNextFrame) else {
                activatePassthroughOnNextFrame = false
  
                removeTransientInputs()
                textureInputSemaphore.signal()
                updateTargetsWithTexture(outputTexture, trackID: trackID)
                let _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
                
                return
            }
            
            if let alternateRenderingFunction = metalPerformanceShaderPathway, useMetalPerformanceShaders {
                var rotatedInputTextures: [UInt: Texture]
                if (firstInputTexture.orientation.rotationNeeded(for: .portrait) != .noRotation) {
                    let rotationOutputTexture = Texture(device: self.currentDevice.device, orientation: .portrait, width: outputWidth, height: outputHeight)
                    guard let rotationCommandBuffer = self.currentDevice.commandQueue.makeCommandBuffer() else {return}
                    rotationCommandBuffer.renderQuad(
                        pipelineState: self.currentDevice.passthroughRenderState,
                        uniformSettings: uniformSettings, inputTextures: inputTextures,
                        useNormalizedTextureCoordinates: useNormalizedTextureCoordinates,
                        outputTexture: rotationOutputTexture,
                        device: self.currentDevice)
                    rotationCommandBuffer.commit()
                    rotatedInputTextures = inputTextures
                    rotatedInputTextures[0] = rotationOutputTexture
                } else {
                    rotatedInputTextures = inputTextures
                }
                alternateRenderingFunction(commandBuffer, rotatedInputTextures, outputTexture)
            } else {
                internalRenderFunction(commandBuffer: commandBuffer, outputTexture: outputTexture)
            }
            commandBuffer.addCompletedHandler { (buffer) in
                self.removeTransientInputs()
                self.textureInputSemaphore.signal()
                
                
            }
            commandBuffer.commit()
            self.updateTargetsWithTexture(outputTexture, trackID: trackID)
            let _ = self.textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func removeTransientInputs() {
        for index in 0..<self.maximumInputs {
            if let texture = inputTextures[index], texture.timingStyle.isTransient() {
                inputTextures[index] = nil
            }
        }
    }
    
    func internalRenderFunction(commandBuffer: MTLCommandBuffer, outputTexture: Texture) {
        commandBuffer.renderQuad(pipelineState: renderPipelineState,
                                 uniformSettings: uniformSettings,
                                 inputTextures: inputTextures,
                                 useNormalizedTextureCoordinates: useNormalizedTextureCoordinates,
                                 outputTexture: outputTexture,
                                 device: self.currentDevice)
    }
}
