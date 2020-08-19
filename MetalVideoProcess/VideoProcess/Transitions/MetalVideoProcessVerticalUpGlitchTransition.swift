//
//  MetalVideoProcessVerticalGlitchTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessVerticalUpGlitchTransition: MetalVideoProcessTransition {
    public var iResolution: Size = Size(width: 1, height: 1) { didSet { uniformSettings["iResolution"] = iResolution } }
    
    public init() {
        super.init(fragmentFunctionName: "verticalupGlitch", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .linearInterpolation
        iResolution = Size(width: 1, height: 1)
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
        self.iResolution = Size(width: Float(texture.texture.width), height: Float(texture.texture.height))

    }
}
