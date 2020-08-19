//
//  MetalVideoProcessFilterGroup.swift
//
//  Created by RenZhu Macro on 2020/4/23.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import CoreMedia
import Metal

open class MetalVideoProcessFilterGroup: ImageProcessingOperation {
    public var debugName: String = ""
    
    /// 时间轴信息，创建FIlter后默认为Zero 则全部纹理接受后都处理，若有值则匹配后处理
    public var timelineRange: CMTimeRange = CMTimeRange.zero
    public var trackID: Int32 = 0 //默认全部生效
    
    public var isEnable: Bool = true
    
    let inputImageRelay = ImageRelay()
    let outputImageRelay = ImageRelay()
    
    public var sources: SourceContainer { get { return inputImageRelay.sources } }
    public var targets: TargetContainer { get { return outputImageRelay.targets } }
    public let maximumInputs: UInt = 1
    
    public func saveUniformSettings(forTimelineRange timeline: CMTimeRange, trackID: Int32) {
        self.timelineRange = timeline
        self.trackID = trackID
    }
    
    public init(trackID: Int32, timelineRange: CMTimeRange = CMTimeRange.zero) {
        self.timelineRange = timelineRange
        self.trackID = trackID
        
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

         inputImageRelay.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
    
    public func configureGroup(_ configurationOperation: (_ input: ImageRelay, _ output: ImageRelay) -> ()) {
        configurationOperation(inputImageRelay, outputImageRelay)
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        outputImageRelay.transmitPreviousImage(to: target, atIndex: atIndex, trackID: trackID)
    }
}
