//
//  MetalVideoProcessCompositor.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/2.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public protocol MetalVideoProcessCompositorDelegate {
    
    /// 外部的帧请求 可以将这个请求缓存下来，使用的时候再读取
    /// - Parameter request: 通过request 可以拿到pixelBuffer outputTime 以及TrackId 一个request包含1个或者多个纹理
    func renderRequest(request: AVAsynchronousVideoCompositionRequest)
    func exportRequest(request: AVAsynchronousVideoCompositionRequest)
}

public class MetalVideoProcessCompositor: NSObject, AVVideoCompositing {

    deinit {
        self.delegate = nil
    }
    
    // MARK: - AVVideoCompositing
    private var renderContext: AVVideoCompositionRenderContext?
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "com.wangrenzhu.metalRender.renderContextQueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "com.wangrenzhu.metalRender.renderQueue")
    public var sourcePixelBufferAttributes: [String: Any]? =
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferMetalCompatibilityKey): true]
    private var shouldCancelAllRequests = false
    public var delegate: MetalVideoProcessCompositorDelegate?
    public var isExport = false
    
    public var requiredPixelBufferAttributesForRenderContext: [String: Any] =
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferMetalCompatibilityKey): true]
    
    public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync(execute: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.renderContext = newRenderContext
            print("renderContext Size: ", newRenderContext.size)
        })
    }
    
    public override init() {
        super.init()
    }
    
    @available(iOS 13.0, *)
    public func prerollForRendering(using renderHint: AVVideoCompositionRenderHint) {
        
    }
    
    @available(iOS 13.0, *)
    public func anticipateRendering(using renderHint: AVVideoCompositionRenderHint) {
        
    }
    
    open func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllRequests = true
        renderingQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shouldCancelAllRequests = false
        }
    }
    
    public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        debugPrint("receiveRequest:", request.compositionTime.seconds)
        renderingQueue.async(execute: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.shouldCancelAllRequests {
                request.finishCancelledRequest()
            } else {
                autoreleasepool {
                    
                    guard let trackID = request.sourceTrackIDs.first else {
                        request.finish(with: NSError(domain: "frame error", code: -1, userInfo: nil))
                        return
                    }
                    guard let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID.int32Value) else
                    {
                        request.finish(with: NSError(domain: "frame error", code: -1, userInfo: nil))
                        return
                    }
                    request.finish(withComposedVideoFrame: sourcePixelBuffer)
                    
                    
                    if (self?.delegate != nil) {
                        if self?.isExport ?? false {
                            self?.delegate?.exportRequest(request: request)
                        } else {
                            self?.delegate?.renderRequest(request: request)
                        }
                    }
                }
            }
        })
        
    }
}
