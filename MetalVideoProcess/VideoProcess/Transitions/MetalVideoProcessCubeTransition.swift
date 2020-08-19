//
//  MetalVideoProcessCubeTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessCubeTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "cubeTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .linearInterpolation
    }
}
