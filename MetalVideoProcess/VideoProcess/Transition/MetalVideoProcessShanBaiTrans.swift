//
//  MetalVideoProcessShanBai.swift
//  MetalVideoProcessShanBai
//  Created by Ruanshengqiang Macro on 2020/5/15.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//
import AVFoundation
/// 闪白转场
public class MetalVideoProcessShanBai: MetalVideoProcessOperation {
    public var renderSize: CGSize? = nil
    public init() {
        super.init(fragmentFunctionName: "shanBai", numberOfInputs: 2, device: sharedMetalRenderingDevice)
    }
    
    public override func newTextureAvailable(_ inputTexture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        self.renderSize = CGSize(width: CGFloat(inputTexture.texture.width), height: CGFloat(inputTexture.texture.height))
    
        super.newTextureWithSize(inputTexture, fromSourceIndex: fromSourceIndex, renderSize: renderSize!, trackID: trackID)
    
    }
}
