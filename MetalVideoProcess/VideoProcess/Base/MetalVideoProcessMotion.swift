//
//  MetalVideoProcessMotion.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/20.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessMotion: MetalVideoProcessOperation {

    public var factor: Float = 1.0 {
        didSet { uniformSettings["factor"] = factor } }
    
    public var roi: CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0) {
        didSet {
            uniformSettings["roi"] = Color(red: Float(roi.origin.x), green:  Float(roi.origin.y), blue: Float(roi.width), alpha: Float(roi.height))
        }
    }
    
    public var timingType: TimingFunctionType = .linearInterpolation
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        
        if self.timelineRange.containsTime(texture.timingStyle.timestamp?.asCMTime ?? CMTime.invalid) {
            let distance = CMTime(seconds: texture.frameTime, preferredTimescale: 1000) - self.timelineRange.start
            let progress = Float(distance.seconds / self.timelineRange.duration.seconds)
            self.factor = self.timingType.timingValue(p: progress)
        }
        
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
}
