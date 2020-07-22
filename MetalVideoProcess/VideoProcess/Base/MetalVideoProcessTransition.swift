//
//  MetalVideoProcessTransition.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/14.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Metal
import AVFoundation

public class MetalVideoProcessTransition: MetalVideoProcessOperation {
    //Transition factor
    public var tweenFactor: Float = 1.0 { didSet { uniformSettings["tweenFactor"] = tweenFactor } }

    public var timingType: TimingFunctionType = .linearInterpolation
    
    open var mainTrackIDs: [Int32] = []

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        guard let sourceIndex = mainTrackIDs.firstIndex(of: trackID) else {
            updateTargetsWithTexture(texture, trackID: trackID)
            return
        }

        if self.timelineRange.containsTime(texture.timingStyle.timestamp?.asCMTime ?? CMTime.invalid) {
            let distance = CMTime(seconds: texture.frameTime, preferredTimescale: 1000) - self.timelineRange.start
            let progress = Float(distance.seconds / self.timelineRange.duration.seconds)
            self.tweenFactor = self.timingType.timingValue(p: progress)
            super.newTextureAvailable(texture, fromSourceIndex: UInt(sourceIndex), trackID: trackID)
        } else {
            updateTargetsWithTexture(texture, trackID: trackID)
        }
    }
}
