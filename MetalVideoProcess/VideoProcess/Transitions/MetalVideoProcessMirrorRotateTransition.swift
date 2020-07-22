//
//  MetalVideoProcessMirrorRotateTransition.swift
//  MetalVideoProcess
//
//  Created by Ruanshengqiang Macro on 2020/7/16.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import AVFoundation
///镜像翻转转场
public class MetalVideoProcessMirrorRotateTransition: MetalVideoProcessTransition {

    public init() {
        super.init(fragmentFunctionName: "mirrorRotateTransition", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        self.timingType = .quadraticEaseOut
    }
}
