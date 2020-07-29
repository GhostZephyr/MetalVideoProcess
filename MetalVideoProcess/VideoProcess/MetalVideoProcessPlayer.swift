//
//  MetalVideoProcessPlayer.swift
//  MetalVideoProcess
//  
//  Created by RenZhu Macro on 2020/5/8.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation
import Metal
import CoreVideo

public protocol MetalVideoProcessPlayerDelegate: NSObjectProtocol {
    
    /// 回放时渲染时间变更
    /// - Parameters: 
    ///   - time: 帧时间
    ///   - player: 当前控制渲染的播放器
    func playbackFrameTimeChanged(frameTime time: CMTime, player: AVPlayer)
    
    /// 回放完毕
    /// - Parameter player: 当前控制渲染的播放器
    func playEnded(currentPlayer player: AVPlayer)
    
    /// 导出完毕
    func finishExport(error: NSError?)
    
    /// 导出进度变更
    /// - Parameter progress: 进度信息
    func exportProgressChanged(_ progress: Float)
}

public class MetalVideoProcessPlayer: ImageSource {
    
    public var trackID: Int32 = 0
    
    deinit {
        debugPrint("##################MetalMoviePlayer deinit: ", self.trackTargets)
        self.trackTargets.removeAll()
        self.requestCache.removeAll()
    }
    
    public func dispose() {
        self.suspend()
        videoFrameProcessingQueue.sync { [weak self] in
            guard let `self` = self else { return }
            self.audioEncodingTarget?.renderVideoFramesemaphore.signal()
            self.audioEncodingTarget?.writeVideoFramesemaphore.signal()
            self.exportVideoFramesemaphore.signal()
            self.renderVideoFramesemaphore.signal()
            
            self.trackTargets.removeAll()
            self.requestCache.removeAll()
            self.player.pause()
            self.exportCompositor?.delegate = nil
            self.playbackCompositor?.delegate = nil
            self.playbackDisplayLink?.isPaused = true
            self.playbackDisplayLink?.invalidate()
            self.playbackDisplayLink = nil
            self.playerDelegate = nil
            self.audioEncodingTarget = nil
            currentRequest = nil
            self.removeAllTargets()
            NotificationCenter.default.removeObserver(self)
        }
        
    }
    
    
    /// 一个id 对应一个Container 默认 id为0
    public var trackTargets : [Int32 : TargetContainer] = [0 : TargetContainer()]
    
    public weak var playerDelegate: MetalVideoProcessPlayerDelegate?
    public let targets = TargetContainer()
    public var runBenchmark = false
    
    var videoTextureCache: CVMetalTextureCache?
    var yuvConversionRenderPipelineState: MTLRenderPipelineState
    var yuvLookupTable: [String: (Int, MTLDataType)] = [: ]
    
    var videoEncodingIsFinished = false
    var audioEncodingIsFinished = false
    
    var videoOutput: AVPlayerItemVideoOutput
    var numberOfFramesCaptured = 0
    var totalFrameTimeDuringCapture: Double = 0.0
    
    /// 导出用
    var assetReader: AVAssetReader?
    public weak var audioEncodingTarget: AudioEncodingTarget?
    
    /// 记录上一次的帧时间用于Refresh操作
    var requestOutputTime: CMTime = .zero
    
    
    /// 当天的请求，用于取PixelBuffer
    public var currentRequest: AVAsynchronousVideoCompositionRequest?
    
    var renderVideoFramesemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    var exportVideoFramesemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    /// Queue以及Player 和 DisplayLink用于实时回放操作
    let videoFrameProcessingQueue = DispatchQueue(
        label: "com.metalvideoprocess.videoFrameProcessingQueue",
        qos: .default)
    
    let videoExportFrameProcessingQueue = DispatchQueue(
        label: "com.metalvideoprocess.videoExportFrameProcessingQueue",
        qos: .default)
    
    let audioExportFrameProcessingQueue = DispatchQueue(
        label: "com.metalvideoprocess.audioFrameProcessingQueue",
        qos: .default)
    
    var player: AVPlayer
    var playerItem: AVPlayerItem
    var isEnded: Bool = false
    var isPlaying: Bool = false
    public var isLooping: Bool = true //是否循环播放
    var playbackDisplayLink: CADisplayLink?
    public var requestCache: MetalVideoProcessCompositionRequestCache = MetalVideoProcessCompositionRequestCache()
    var currentFrame: CMTime
    weak var playbackCompositor: MetalVideoProcessCompositor?
    weak var exportCompositor: MetalVideoProcessCompositor?
    
    var bufferTime: Double = 0.0
    
    /// 根据原始的视频文件初始化一个渲染播放器
    /// - Parameter playerItem: 通过PlayerItem创建回放
    /// - Throws: Reader创建失败
    public init(playerItem: AVPlayerItem,
                audioEncodingTarget: AudioEncodingTarget? = nil) throws {
        let (pipelineState, lookupTable) = generateRenderPipelineState(device: sharedMetalRenderingDevice, vertexFunctionName: "twoInputVertex", fragmentFunctionName: "yuvConversionFullRangeFragment", operationName: "YUVToRGB")
        self.yuvConversionRenderPipelineState = pipelineState
       
        self.yuvLookupTable = lookupTable
        let _ = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, sharedMetalRenderingDevice.device, nil, &videoTextureCache)
        
        self.videoOutput =
            AVPlayerItemVideoOutput(pixelBufferAttributes: 
                [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange))])
         
        self.videoOutput.suppressesPlayerRendering = true
        self.currentFrame = .zero
        self.playerItem = playerItem
        
        self.player = AVPlayer(playerItem: self.playerItem)
        
        self.player.volume = 1.0
        self.playerItem.add(self.videoOutput)
        self.videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: 0.1)
        self.playbackDisplayLink = CADisplayLink(target: self, selector: #selector(renderPlayback(sender:)))
        self.playbackDisplayLink?.isPaused = false
        self.playbackDisplayLink?.add(to: RunLoop.current, forMode: .common)
        self.audioEncodingTarget = audioEncodingTarget

        guard let compositor = self.playerItem.customVideoCompositor as? MetalVideoProcessCompositor else {
            return
        }
        self.playbackCompositor = compositor
        compositor.delegate = self
        self.playerItem.preferredForwardBufferDuration = 0.5
        self.seekTo(time: 0.0)
    }
    
    public func updatePlayerItem(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        
        self.player = AVPlayer(playerItem: self.playerItem)
        
        self.player.volume = 1.0
        
        self.playerItem.add(self.videoOutput)
        
        guard let compositor = self.playerItem.customVideoCompositor as? MetalVideoProcessCompositor else {
            return
        }
        self.playbackCompositor = compositor
        compositor.delegate = self
    }
    
    // MARK: -
    // MARK: Override Target Texture
    
    /// 附加到Target上
    /// - Parameters: 
    ///   - target: 目标Filter
    ///   - atTargetIndex: 所在的位置
    ///   - trackID: 追踪用id
    ///   - targetTrackId: 需要附加的id 默认为0 代表主轴的意思
    public func addTarget(_ target: ImageConsumer, atTargetIndex: UInt? = nil, trackID: Int32 = 0, targetTrackId: Int32 = 0) {
        if let targetIndex = atTargetIndex {
            target.setSource(self, atIndex: targetIndex)
            if let trackContainer = trackTargets[targetTrackId] {
                trackContainer.append(target, indexAtTarget: targetIndex)
            } else {
                let newContainer = TargetContainer()
                newContainer.append(target, indexAtTarget: targetIndex)
                trackTargets[trackID] = newContainer
                
            }
            
        } else if let indexAtTarget = target.addSource(self) {
            
            if let trackContainer = trackTargets[targetTrackId] {
                trackTargets[trackID] = trackContainer //映射到轴上
                trackContainer.append(target, indexAtTarget: indexAtTarget)
            } else {
                let newContainer = TargetContainer()
                newContainer.append(target, indexAtTarget: indexAtTarget)
                trackTargets[trackID] = newContainer
                
            }
        } else {
            guard let trackContainer = trackTargets[targetTrackId] else {
                let newContainer = TargetContainer()
                newContainer.append(target, indexAtTarget: 0)
                trackTargets[trackID] = newContainer
                return
            }
            trackContainer.append(target, indexAtTarget: 0)
            //如果存在则生成一个新的映射
            trackTargets[trackID] = trackContainer
            
        }
    }
    
    public func removeAllTargets() {
        for keyValue in self.trackTargets {
            let targets = keyValue.value
            for (target, index) in targets {
                target.removeSourceAtIndex(index)
            }
            targets.removeAll()
        }
        self.targets.removeAll()
    }
    
    func updateTrackTargetsWithTexture(_ texture: Texture, trackID: Int32) {
        guard let targets = self.trackTargets[trackID] else {
            if self.trackTargets.count == 0 {
                searchVisialbeTargets(targets: self.targets, texture: texture, trackID: trackID)
            }
            return
        }
        searchVisialbeTargets(targets: targets, texture: texture, trackID: trackID)
    }
    
    //    // MARK: -
    //    // MARK: Export
    
    public func startExport() throws {
        self.playbackDisplayLink?.isPaused = true
        self.pause()
        assetReader = nil
        videoEncodingIsFinished = false
        audioEncodingIsFinished = false
        self.assetReader = try AVAssetReader(asset: playerItem.asset)
        let outputSettings: [String: Any] =
            [kCVPixelBufferMetalCompatibilityKey as String: true,
             (kCVPixelBufferPixelFormatTypeKey as String): NSNumber(value: Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
        let videoTracks = playerItem.asset.tracks(withMediaType: .video)
        let audioTracks = playerItem.asset.tracks(withMediaType: .audio)
        
        var readerVideoTrackOutput =
            AVAssetReaderVideoCompositionOutput(videoTracks: videoTracks,
                                                videoSettings: outputSettings)
        readerVideoTrackOutput.videoComposition = self.playerItem.videoComposition
        readerVideoTrackOutput.alwaysCopiesSampleData = false
        
        var readerAudioTrackOutput: AVAssetReaderAudioMixOutput?
        
        if audioTracks.count > 0 {
            readerAudioTrackOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: nil)
            readerAudioTrackOutput?.alwaysCopiesSampleData = false
        }
        
        
        
        guard let compositor = readerVideoTrackOutput.customVideoCompositor as? MetalVideoProcessCompositor else {
            return
        }
        compositor.delegate = self
        self.exportCompositor = compositor
        self.exportCompositor?.isExport = true
        
        self.assetReader?.add(readerVideoTrackOutput)
        
        if let audioOutput = readerAudioTrackOutput {
            self.assetReader?.add(audioOutput)
        }
        
        for output in self.assetReader?.outputs ?? [] {
            if(output.mediaType == AVMediaType.video) {
                readerVideoTrackOutput = output as! AVAssetReaderVideoCompositionOutput
            }
            
            if(output.mediaType == .audio) {
                readerAudioTrackOutput = output as? AVAssetReaderAudioMixOutput
            }
        }
        let duration = self.playerItem.duration
        let startTime = CFAbsoluteTimeGetCurrent()
        self.videoFrameProcessingQueue.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            debugPrint("准备开始处理 总时长为: ", duration.seconds," 当前时间: ", startTime)
            self.videoExportFrameProcessingQueue.async { [weak self] in
                guard let `self` = self else {
                    return
                }
                guard self.assetReader?.startReading() ?? false else {
                    debugPrint("Couldn't start reading")
                    return
                }
                
                while (self.assetReader?.status == .reading) {
                    //读一帧写一帧
                    let rs = self.audioEncodingTarget?.writeVideoFramesemaphore.wait(timeout: .now() + 0.5)
                    if rs == .timedOut {
                        usleep(100000)
                        self.readFrame(readerVideoTrackOutput: readerVideoTrackOutput,
                                       duration: duration,
                                       readerAudioTrackOutput: readerAudioTrackOutput)
                        self.audioEncodingTarget?.renderVideoFramesemaphore.signal()
                        continue
                    }
                    self.readFrame(readerVideoTrackOutput: readerVideoTrackOutput,
                                   duration: duration,
                                   readerAudioTrackOutput: readerAudioTrackOutput)
                    //这里发起了视频帧的读取信号
                    
                    
                }
                
                debugPrint("导出消耗时间: ", CFAbsoluteTimeGetCurrent() - startTime)
                self.videoEncodingIsFinished = true
                self.audioEncodingIsFinished = true
                self.audioEncodingTarget?.renderVideoFramesemaphore.signal()
                self.audioEncodingTarget?.writeAudioFramesemaphore.signal()
                self.audioEncodingTarget?.renderVideoFramesemaphore.signal()
                self.endProcessing()
                if self.playerDelegate != nil {
                    self.playerDelegate?.finishExport(error: nil)
                }
                self.playbackDisplayLink?.isPaused = false
                
            }
        }
    }
    
    func readFrame(readerVideoTrackOutput: AVAssetReaderVideoCompositionOutput,
                   duration: CMTime,
                   readerAudioTrackOutput: AVAssetReaderAudioMixOutput? = nil) {
        let frameTime = self.readNextVideoFrame(from: readerVideoTrackOutput)
        self.audioEncodingTarget?.processVideoFrameTime(frameTime)
        let progress = frameTime.seconds / duration.seconds
        if self.playerDelegate != nil {
            self.playerDelegate?.exportProgressChanged(Float(progress))
        }
        
        if let audioOutput = readerAudioTrackOutput {
            self.audioExportFrameProcessingQueue.async {
                self.readNextAudioFrame(from: audioOutput)
                
            }
        }
        var waitCount = 0
        while (frameTime - self.audioEncodingTarget!.previousFrameTime).seconds > self.bufferTime {
            usleep(10000)
            waitCount += 1
            if waitCount > 50 {
                debugPrint("等待超时")
                break
            }
        }
    }
    
    func readNextVideoFrame(from videoTrackOutput: AVAssetReaderOutput) -> CMTime {
        if ((self.assetReader?.status == .reading) && !videoEncodingIsFinished) {
            if let sampleBuffer = videoTrackOutput.copyNextSampleBuffer() {
                let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                debugPrint("Video 请求视频帧: ", frameTime.seconds)
                CMSampleBufferInvalidate(sampleBuffer)
                return frameTime
            } else {
                
                videoEncodingIsFinished = true
                self.audioEncodingTarget?.writeVideoFramesemaphore.signal()
            }
        }
        return CMTime.zero
    }
    
    func readNextAudioFrame(from audioTrackOutput: AVAssetReaderOutput) {
        if ((self.assetReader?.status == .reading) && !audioEncodingIsFinished) {
            if let sampleBuffer = audioTrackOutput.copyNextSampleBuffer() {
                //                debugPrint("Audio拿到了音频帧: ", CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds)
                if self.audioEncodingTarget != nil {
                    
                    self.audioEncodingTarget?.processAudioBuffer(sampleBuffer)
                }
                
                CMSampleBufferInvalidate(sampleBuffer)
            } else {
                audioEncodingIsFinished = true
                self.audioEncodingTarget?.writeAudioFramesemaphore.signal()
            }
        }
    }
    
    public func cancel() {
        self.pause()
        self.endProcessing()
    }
    
    // MARK: -
    // MARK: Rendering
    /// 处理输出的Pixelbuffer 这里的大小宽高可能是一致的，也许带有黑边，所以可能需要进行二次处理
    /// - Parameters: 
    ///   - movieFrame: 拿到的纹理帧
    ///   - withSampleTime: 帧时间
    func process(movieFrame: CVPixelBuffer, withSampleTime: CMTime, trackID: Int32 = 0) {
        let bufferHeight = CVPixelBufferGetHeight(movieFrame)
        let bufferWidth = CVPixelBufferGetWidth(movieFrame)
        CVPixelBufferLockBaseAddress(movieFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let conversionMatrix = colorConversionMatrix601FullRangeDefault
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let texture: Texture?
        var luminanceTextureRef: CVMetalTexture? = nil
        var chrominanceTextureRef: CVMetalTexture? = nil
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, movieFrame, nil, .r8Unorm, bufferWidth, bufferHeight, 0, &luminanceTextureRef)
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, movieFrame, nil, .rg8Unorm, bufferWidth / 2, bufferHeight / 2, 1, &chrominanceTextureRef)
        
        if let concreteLuminanceTextureRef = luminanceTextureRef, let concreteChrominanceTextureRef = chrominanceTextureRef,
            let luminanceTexture = CVMetalTextureGetTexture(concreteLuminanceTextureRef), let chrominanceTexture = CVMetalTextureGetTexture(concreteChrominanceTextureRef) {
            let outputTexture = Texture(device: sharedMetalRenderingDevice.device,
                                        orientation: .portrait,
                                        width: bufferWidth,
                                        height: bufferHeight,
                                        timingStyle: .videoFrame(timestamp: Timestamp(withSampleTime)))
            
            convertYUVToRGB(pipelineState: self.yuvConversionRenderPipelineState, lookupTable: self.yuvLookupTable,
                            luminanceTexture: Texture(orientation: .portrait,
                                                      texture: luminanceTexture),
                            chrominanceTexture: Texture(orientation: .portrait,
                                                        texture: chrominanceTexture),
                            resultTexture: outputTexture, colorConversionMatrix: conversionMatrix)
            texture = outputTexture
        } else {
            texture = nil
        }
        
        CVPixelBufferUnlockBaseAddress(movieFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        if texture != nil {
            texture!.frameTime = withSampleTime.seconds
            self.updateTrackTargetsWithTexture(texture!, trackID: trackID)
        }
        
        if self.runBenchmark {
            let currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime)
            self.numberOfFramesCaptured += 1
            self.totalFrameTimeDuringCapture += currentFrameTime
            debugPrint("Average frame time: \(1000.0 * self.totalFrameTimeDuringCapture / Double(self.numberOfFramesCaptured)) ms")
            debugPrint("Current frame time: \(1000.0 * currentFrameTime) ms")
        }
    }
    
    func endProcessing() {
        assetReader?.cancelReading()
        assetReader = nil
    }
    
    public func start() {
        self.seekTo(time: 0.0)
        self.isPlaying = true
        self.player.play()
        self.playbackDisplayLink?.isPaused = false
    }
    
    // MARK: -
    // MARK: Playback control
    public func play() {
        self.endProcessing()
        self.isPlaying = true
        if self.isEnded {
            self.start()
            return
        }
        self.player.play()
        self.playbackDisplayLink?.isPaused = false
    }
    
    public func pause() {
        self.endProcessing()
        self.isPlaying = false
        self.player.pause()
    }
    
    public func seekTo(time: Float64) {
        self.endProcessing()
        self.isPlaying = false
        self.isEnded = false
        self.player.pause()
        self.renderVideoFramesemaphore.signal()
        self.playbackDisplayLink?.isPaused = false
        let outputTime = CMTime(seconds: time, preferredTimescale: 1000000)
        player.seek(to: outputTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    @objc internal func playerItemDidPlayToEndTime(_ aNotification: Notification?) {
        
        self.isEnded = true
        self.isPlaying = false
        self.requestCache.removeAll()
        if self.isLooping {
            self.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] (result) in
                guard let `self` = self else { return }
                self.play()
            }
        }
    }
    
    public func suspend() {
        self.playbackDisplayLink?.isPaused = true
        self.videoFrameProcessingQueue.sync {
            debugPrint("suspend ###################")
        }
    }
    
    public func resume() {
        self.playbackDisplayLink?.isPaused = false
    }
    
    @objc public func renderPlayback(sender: CADisplayLink) {
        if sender.isPaused {
            return
        }
        
        self.videoFrameProcessingQueue.async { [weak self] in
            guard let `self` = self else { return }
            if (self.playbackDisplayLink?.isPaused ?? false) {
                debugPrint("渲染已被暂停立即返回")
                return
            }
            if self.isPlaying {
                
                let currentTime = self.player.currentTime()
                let itemTime = self.playerItem.duration
                if currentTime == itemTime {
                    self.playerItemDidPlayToEndTime(nil)
                    return
                }
            }
            var newTime: CMTime = CMTime.zero
            var outputItemTime = CMTime.invalid
            
            // Calculate the nextVsync time which is when the screen will be refreshed next.
            let nextVSync = (sender.timestamp + sender.duration)
            
            outputItemTime = self.videoOutput.itemTime(forHostTime: nextVSync)
            
            if self.videoOutput.hasNewPixelBuffer(forItemTime: outputItemTime) {
                guard let _ = self.videoOutput.copyPixelBuffer(forItemTime: outputItemTime,
                                                               itemTimeForDisplay: &newTime)
                    else {
                        return
                }
                self.requestOutputTime = newTime
                if self.isPlaying {
                    debugPrint("prepare rendering: ", newTime.seconds)
                    guard let request = self.requestCache.getRequest(time: newTime) else {
                        self.requestCache.clearCacheWithTime(newTime)
                        return
                    }
                    
                    self.currentRequest = request
                    
                    autoreleasepool {
                        self.process(request: request, newTime: newTime)
                    }
                    self.requestCache.removeRequest(time: newTime)
                } else {
                    autoreleasepool {
                        guard let request = self.currentRequest else {
                            return
                        }
                        self.process(request: request, newTime: request.compositionTime)
                    }
                }
                if sender.isPaused {
                    self.pause()
                    return
                }
                if newTime != self.currentFrame {
                    self.currentFrame = newTime
                    if self.playerDelegate != nil {
                        self.playerDelegate?.playbackFrameTimeChanged(frameTime: self.currentFrame, player: self.player)
                    }
                }
            } else {
                
                guard let request = self.currentRequest else {
                    return
                }
                autoreleasepool {
                    self.process(request: request, newTime: request.compositionTime)
                }
                if !self.isPlaying {
                    self.requestCache.removeAll()
                } else {
                    self.videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: 1.0)
                }
                
            }
        }
        if self.isPlaying && self.playerDelegate != nil {
            self.playerDelegate?.playbackFrameTimeChanged(frameTime: self.player.currentTime(), player: self.player)
        }
        
    }
    
    func process(request: AVAsynchronousVideoCompositionRequest, newTime: CMTime) {
        if self.playbackDisplayLink?.isPaused ?? true {
            return 
        }
        guard let instructions = request.videoCompositionInstruction as? VideoCompositionInstruction else {
            return
        }

        for (_, layer) in instructions.layerInstructions.enumerated() {
            if let provider = (layer.videoCompositionProvider as? MetalVideoEditorItem) {
                if provider.itemType == .video {
                    guard let pixelBuffer = request.sourceFrame(byTrackID: provider.trackID) else {
//                        debugPrint("居然没找到这个纹理？？？: ", trackID) //输出黑帧
                        continue
                    }
                    self.process(movieFrame: pixelBuffer,
                                 withSampleTime: newTime,
                                 trackID: provider.trackID)
                } else if provider.itemType == .image {
                    //image是已经渲染好的texture 直接传递
                    guard let imageResoure = provider.resource as? ImageResource else {
                        continue
                    }
                    if let texture = imageResoure.sourceTexture(at: newTime) {
                        let rsTexture = Texture(orientation: .portrait, texture: texture)
                        rsTexture.frameTime = newTime.seconds
                        self.updateTrackTargetsWithTexture(rsTexture, trackID: provider.trackID)
                    }
                } else {
                    //序列帧动画资源暂不处理
                }
            }
            
        }
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        
    }
    
}

