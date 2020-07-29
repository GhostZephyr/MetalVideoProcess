//
//  MetalVideoProcessMoveInMotion.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/21.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import UIKit

public  class MetalVideoProcessZoomInMotion: MetalVideoProcessMotion {
 
    public init() {
        super.init(fragmentFunctionName: "zoomInMotion", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .quadraticEaseIn
        self.factor = 0.0
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        if let time = texture.timingStyle.timestamp?.asCMTime {
            if time < timelineRange.start {
                factor = 0.0
            }
            
            debugPrint("moveInMotion:", factor, " frameTime:", texture.frameTime)
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
        }
    }
    
    /// before fade in, we need the texture alpha  keep to zero
    /// - Parameter texture: texture
    /// - Returns: result
    public override func checkTimelineRange(with texture: Texture) -> (Bool) {
        return true
    }
}
