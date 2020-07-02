//
//  MetalVideoProcessMovieWriter.swift
//  MetalVideoProcessMovieWriter
//
//  Created by RenZhu Macro on 2020/5/28.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

public protocol AudioEncodingTarget: NSObjectProtocol {
    func activateAudioTrack()
    func processAudioBuffer(_ sampleBuffer: CMSampleBuffer)
    var writeVideoFramesemaphore: DispatchSemaphore { get }
    var renderVideoFramesemaphore: DispatchSemaphore { get }
    var writeAudioFramesemaphore: DispatchSemaphore { get }
    /// 传入正在请求的视频帧数
    /// - Parameter videoFrameTime: 视频帧时间
    func processVideoFrameTime(_ videoFrameTime: CMTime)
    var previousFrameTime: CMTime { get }
    
}

public let hasHEVCHardwareEncoder: Bool = {
    let spec: [CFString: Any]
    #if os(macOS)
    spec = [ kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: true ]
    #else
    spec = [: ]
    #endif
    var outID: CFString?
    var properties: CFDictionary?
    
    if #available(iOS 11.0, *) {
        let result = VTCopySupportedPropertyDictionaryForEncoder(width: 1920, height: 1080, codecType: kCMVideoCodecType_HEVC, encoderSpecification: spec as CFDictionary, encoderIDOut: &outID, supportedPropertiesOut: &properties)
        if result == kVTCouldNotFindVideoEncoderErr {
            return false // no hardware HEVC encoder
        }
        return result == noErr
    } else {
        return false
        // Fallback on earlier versions
    }
    
}()


public class MetalVideoProcessMovieWriter: NSObject, ImageConsumer, AudioEncodingTarget {
    
    public var isEnable: Bool = true
    
    public let sources = SourceContainer()
    public let maximumInputs: UInt = 1
    
    let assetWriter: AVAssetWriter
    let assetWriterVideoInput: AVAssetWriterInput
    var assetWriterAudioInput: AVAssetWriterInput?
    let assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    let size: Size
    
    public var fileURL: URL
    private var isRecording = false
    private var videoEncodingIsFinished = false
    private var audioEncodingIsFinished = false
    private var startTime: CMTime?
    public var previousFrameTime = CMTime.negativeInfinity
    private var previousRequesVideoTime = CMTime.zero
    private var previousAudioTime = CMTime.negativeInfinity
    private var encodingLiveVideo: Bool
    private var signalOnce: Bool = false
    var pixelBuffer: CVPixelBuffer? = nil
    public var writeVideoFramesemaphore: DispatchSemaphore = DispatchSemaphore(value: 2)
    public var renderVideoFramesemaphore: DispatchSemaphore = DispatchSemaphore(value: 2)
    public var writeAudioFramesemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    public let requestQueue = DispatchQueue(label: "com.metalvideoprocess.requestQueue", qos: .background)
    var renderPipelineState: MTLRenderPipelineState!
    
    var transform: CGAffineTransform {
        get {
            return assetWriterVideoInput.transform
        }
        set {
            assetWriterVideoInput.transform = newValue
        }
    }
    
    public init(URL: Foundation.URL,
                size: Size,
                fileType: AVFileType = AVFileType.mov,
                liveVideo: Bool = false,
                settings: [String: AnyObject]? = nil) throws {
        self.fileURL = URL
        self.size = size
        assetWriter = try AVAssetWriter(url: URL, fileType: fileType)
        assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, preferredTimescale: 1000)
        debugPrint("support h265: ", hasHEVCHardwareEncoder)
        var localSettings: [String: AnyObject]
        if let settings = settings {
            localSettings = settings
        } else {
            localSettings = [String: AnyObject]()
        }
        
        if hasHEVCHardwareEncoder {
            if #available(iOS 11.0, *) {
                localSettings[AVVideoCodecKey] = AVVideoCodecType.hevc as NSString
            }
        } else {
            localSettings[AVVideoCodecKey] =  localSettings[AVVideoCodecKey] ?? AVVideoCodecType.h264 as NSString
        }
        
        localSettings[AVVideoWidthKey] = localSettings[AVVideoWidthKey] ?? NSNumber(value: size.width)
        localSettings[AVVideoHeightKey] = localSettings[AVVideoHeightKey] ?? NSNumber(value: size.height)
        
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: localSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        encodingLiveVideo = liveVideo
        
        let sourcePixelBufferAttributesDictionary: [String: AnyObject] =
            [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int32(kCVPixelFormatType_32BGRA)),
             kCVPixelBufferWidthKey as String: NSNumber(value: size.width),
             kCVPixelBufferHeightKey as String: NSNumber(value: size.height)]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        assetWriter.add(assetWriterVideoInput)
        
        let (pipelineState, _) = generateRenderPipelineState(device: sharedMetalRenderingDevice, vertexFunctionName: "oneInputVertex", fragmentFunctionName: "passthroughFragment", operationName: "RenderView")
        self.renderPipelineState = pipelineState
    }
    
    public func startRecording(transform: CGAffineTransform? = nil) {
        if let transform = transform {
            assetWriterVideoInput.transform = transform
        }
        startTime = .zero
        self.isRecording = self.assetWriter.startWriting()
        self.assetWriter.startSession(atSourceTime: startTime!)
    }
    
    public func finishRecording(_ completionCallback: (() -> Void)? = nil) {
        self.isRecording = false
        previousFrameTime = .negativeInfinity
        previousAudioTime = .negativeInfinity
        previousRequesVideoTime = .zero
        self.writeAudioFramesemaphore.signal()
        self.writeVideoFramesemaphore.signal()
        self.startTime = .zero
        if (self.assetWriter.status == .completed || self.assetWriter.status == .cancelled || self.assetWriter.status == .unknown) {
            DispatchQueue.global().async{
                completionCallback?()
            }
            return
        }
        if ((self.assetWriter.status == .writing) && (!self.videoEncodingIsFinished)) {
            self.videoEncodingIsFinished = true
            self.assetWriterVideoInput.markAsFinished()
        }
        if ((self.assetWriter.status == .writing) && (!self.audioEncodingIsFinished)) {
            self.audioEncodingIsFinished = true
            self.assetWriterAudioInput?.markAsFinished()
        }
        
        if let callback = completionCallback {
            self.assetWriter.finishWriting(completionHandler: callback)
        } else {
            self.assetWriter.finishWriting{}
            
        }
    }
    
    public func processVideoFrameTime(_ videoFrameTime: CMTime) {
        self.previousRequesVideoTime = videoFrameTime
    }
    
    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        self.requestQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            guard self.isRecording else {
                return
                
            }
            
            
            
            guard let frameTime = texture.timingStyle.timestamp?.asCMTime else {
                return
                
            }
            //            debugPrint("准备写入 收到渲染完毕的视频帧: ", frameTime.seconds, " 上一个请求的视频帧: ", self.previousRequesVideoTime.seconds)
            
            guard (frameTime != self.previousFrameTime) else {
                self.writeVideoFramesemaphore.signal()
                self.renderVideoFramesemaphore.signal()
                return
                
            }
            
            self.previousFrameTime = frameTime
            while self.assetWriter.status != .writing {
                debugPrint("当前无法写入休眠中")
                usleep(1000)
            }
            
            if (self.startTime == nil) {
                debugPrint("startTime = nil: ", self.startTime?.seconds ?? 0.0)
                if (self.assetWriter.status != .writing) {
                    self.assetWriter.startWriting()
                }
                
                self.assetWriter.startSession(atSourceTime: frameTime)
                self.startTime = frameTime
                self.assetWriterVideoInput.requestMediaDataWhenReady(on: self.requestQueue) { [weak self] in
                    guard let `self` = self else { return }
                    if !self.signalOnce {
                        self.signalOnce = true
                        self.writeVideoFramesemaphore.signal()
                        self.renderVideoFramesemaphore.signal()
                    }
                }
            }
            
            
            //        let _ = self.writeVideoFramesemaphore.wait(timeout: DispatchTime.distantFuture)
            
            guard (self.assetWriterVideoInput.isReadyForMoreMediaData || (!self.encodingLiveVideo)) else {
                debugPrint("Had to drop a frame at time \(frameTime)")
                return
            }
            
            guard let pool  = self.assetWriterPixelBufferInput.pixelBufferPool else {
                return
            }
            
            
            
            var pixelBufferFromPool: CVPixelBuffer? = nil
            
            let pixelBufferStatus = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBufferFromPool)
            guard let pixelBuffer = pixelBufferFromPool, (pixelBufferStatus == kCVReturnSuccess) else { return }
            while !self.assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData  {
                debugPrint("可能要丢帧了 准备休眠 frameTime: \(frameTime.seconds)")
                usleep(1000)
            }
            if !self.assetWriterPixelBufferInput.assetWriterInput.isReadyForMoreMediaData {
                print("等待了1秒 还是无法写入 准备跳帧")
                self.writeVideoFramesemaphore.signal()
                self.renderVideoFramesemaphore.signal()
                return
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            self.renderIntoPixelBuffer(pixelBuffer, texture: texture)
            
            
            if (!self.assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: frameTime)) {
                print("Problem appending pixel buffer at time: \(frameTime)")
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            
            debugPrint("写入完毕 视频帧: ", frameTime.seconds, " 上一个请求的视频帧: ", self.previousRequesVideoTime.seconds)
            
            self.writeVideoFramesemaphore.signal()
            self.renderVideoFramesemaphore.signal()
        }
        
    }
    
    func renderIntoPixelBuffer(_ pixelBuffer: CVPixelBuffer, texture: Texture) {
        guard let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Could not get buffer bytes")
            return
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let outputTexture: Texture
        let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
        
        outputTexture = Texture(device: sharedMetalRenderingDevice.device, orientation: .portrait, width: Int(round(self.size.width)), height: Int(round(self.size.height)), timingStyle: texture.timingStyle)
        
        commandBuffer?.renderQuad(pipelineState: renderPipelineState, inputTextures: [0: texture], outputTexture: outputTexture)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        let region = MTLRegionMake2D(0, 0, outputTexture.texture.width, outputTexture.texture.height)
        
        outputTexture.texture.getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
    }
    
    // MARK: -
    // MARK: Audio support
    
    public func activateAudioTrack() {
        // TODO: Add ability to set custom output settings
        assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        assetWriter.add(assetWriterAudioInput!)
        assetWriterAudioInput?.expectsMediaDataInRealTime = encodingLiveVideo
    }
    
    public func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let assetWriterAudioInput = assetWriterAudioInput else { return }
        
        let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        if (self.startTime == nil) {
            if (self.assetWriter.status != .writing) {
                self.assetWriter.startWriting()
            }
            
            self.assetWriter.startSession(atSourceTime: currentSampleTime)
            assetWriterAudioInput.requestMediaDataWhenReady(on: self.requestQueue) { [weak self] in
                guard let `self` = self else { return }
                
                self.writeAudioFramesemaphore.signal()
            }
            
            self.startTime = currentSampleTime
        }
        
        while !assetWriterAudioInput.isReadyForMoreMediaData || currentSampleTime > previousFrameTime  {
            usleep(10000)
        }

        guard (assetWriterAudioInput.isReadyForMoreMediaData || (!self.encodingLiveVideo)) else {
            return
        }
        
        if (!assetWriterAudioInput.append(sampleBuffer)) {
            print("Trouble appending audio sample buffer")
        }
    }
}
