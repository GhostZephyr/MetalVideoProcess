//
//  MetalVideoProcessColorFilter.swift
//  MetalVideoProcessColorFilter
//  
//  Created by wangrenzhu Macro on 2020/5/15.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessColorFilter: MetalVideoProcessOperation  {
    public var renderSize: CGSize? = nil

    public var color: Color
    {
        get {
            return uniformSettings["color"]
        }
        set {
            uniformSettings["color"] = newValue
        }
    }
    
    public var strength: Float
    {
        get {
            return uniformSettings["strength"]
        }
        set {
            uniformSettings["strength"] = newValue
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "colorFragment",
                   numberOfInputs: 1, device: sharedMetalRenderingDevice)
        strength = 1.0
        renderSize = MetalVideoProcessBackground.canvasSize
    }
    
    public override func newTextureAvailable(_ inputTexture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        renderSize = MetalVideoProcessBackground.canvasSize
        super.newTextureWithSize(inputTexture, fromSourceIndex: fromSourceIndex, renderSize: renderSize!, trackID: trackID)
    }
}
