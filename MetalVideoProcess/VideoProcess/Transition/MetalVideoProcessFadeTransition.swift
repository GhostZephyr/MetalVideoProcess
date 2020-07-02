//
//  MetalVideoProcessFadeTransition.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessFadeTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "fadeTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
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
