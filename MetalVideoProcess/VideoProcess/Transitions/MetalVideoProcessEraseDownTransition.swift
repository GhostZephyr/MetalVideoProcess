//
//  MetalVideoProcessEraseDownTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import AVFoundation
///向下擦除转场
public class MetalVideoProcessEraseDownTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "eraseDownTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .quadraticEaseOut
    }
   
}
