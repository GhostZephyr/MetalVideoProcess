
//
//  OrpheusMetalRenderLuminance.swift
//  OrpheusMetalRenderLuminance
//
//  Created by Ruanshengqiang Macro on 2020/5/15.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//
import Foundation

public class MetalVideoProcessLuminance: MetalVideoProcessOperation {
    public init() {
        super.init(fragmentFunctionName: "luminanceFragment", numberOfInputs: 1, device: sharedMetalRenderingDevice)
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {

        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
    
}
