//
//  MetalVideoProcessFadeOutMotion.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/21.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import UIKit

public class MetalVideoProcessFadeOutMotion: MetalVideoProcessMotion {
    
    public init() {
        super.init(fragmentFunctionName: "fadeOutMotion", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .quadraticEaseOut
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        if let time = texture.timingStyle.timestamp?.asCMTime {
            if time > timelineRange.end {
                factor = 1.0
            } else if time < timelineRange.start {
                self.updateTargetsWithTexture(texture, trackID: trackID)
                return
            }
            debugPrint("fadeout:", factor, " frameTime:", texture.frameTime)
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
        }
    }
    
    /// after fade out, we need the texture alpha keep to zero
    /// - Parameter texture: texture
    /// - Returns: result
    public override func checkTimelineRange(with texture: Texture) -> (Bool) {
        return true
    }
}
