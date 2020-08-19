//
//  MetalVideoProcessFadeTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessFadeTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "fadeTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .quadraticEaseOut
    }
}
