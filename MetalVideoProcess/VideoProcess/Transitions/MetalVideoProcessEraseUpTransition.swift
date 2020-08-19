//
//  MetalVideoProcessEraseUpTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessEraseUpTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "eraseUpTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .linearInterpolation
    }
}
