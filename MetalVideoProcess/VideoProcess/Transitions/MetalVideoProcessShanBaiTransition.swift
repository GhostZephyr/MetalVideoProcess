//
//  MetalVideoProcessShanBai.swift
//  MetalVideoProcessShanBai
//  Created by Ruanshengqiang Macro on 2020/5/15.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//
import AVFoundation
/// 闪白转场
public class MetalVideoProcessShanBaiTransition: MetalVideoProcessTransition {
    public var renderSize: CGSize? = nil
    public init() {
        super.init(fragmentFunctionName: "shanBai", numberOfInputs: 2, device: sharedMetalRenderingDevice)
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        if self.timelineRange.containsTime(texture.timingStyle.timestamp?.asCMTime ?? CMTime.invalid) {
            let distance = CMTime(seconds: texture.frameTime, preferredTimescale: 1000) - self.timelineRange.start
            let progress = distance.seconds / self.timelineRange.duration.seconds
            self.tweenFactor = TimingFunctionFactory.quadraticEaseOut(p: Float(progress))
        }
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
}
