//
//  MetalVideoProcessAlphaBlend.swift
//  MetalVideoProcessAlphaBlend
//  Created by RenZhu Macro on 2020/5/15.
//  Copyright © 2020 wangrenzhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessBlendFilter: MetalVideoProcessOperation {
    public var mix: Float = 1.0 { didSet { uniformSettings["mixturePercent"] = mix } }
    public var blendMode: Blendmode = .Alpha { didSet {
        uniformSettings["blendMode"] =  blendMode.rawValue } }
    
    public enum Blendmode: Float {
        case Alpha = 0.0
        case Mask = 1.0
    }
    public var renderSize: CGSize? = nil
    public init() {
        super.init(fragmentFunctionName: "alphaBlend", numberOfInputs: 2, device: sharedMetalRenderingDevice)
        ({mix = 1.0})()
        ({blendMode = .Alpha})()
    }
    
    public override func newTextureAvailable(_ inputTexture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        self.renderSize = CGSize(width: CGFloat(inputTexture.texture.width), height: CGFloat(inputTexture.texture.height))
    
        super.newTextureWithSize(inputTexture, fromSourceIndex: fromSourceIndex, renderSize: renderSize!, trackID: trackID)
    
    }
}
