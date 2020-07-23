//
//  MetalVideoProcessBurnTransition.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessBurnTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "burnTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .linearInterpolation
    }
}
