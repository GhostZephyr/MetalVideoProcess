//
//  MetalVideoProcessTransition.swift
//  MetalVideoProcess
//
//  Created by RenZhu Macro on 2020/7/14.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Metal
import CoreImage

public class MetalVideoProcessTransition: MetalVideoProcessOperation {
    //Transition factor
    public var tweenFactor: Float = 1.0 { didSet { uniformSettings["tweenFactor"] = tweenFactor } }
//    
    open var mainTrackIDs: [Int32] = []

    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        guard let sourceIndex = mainTrackIDs.firstIndex(of: trackID) else {
            super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
            return
        }
        let testImage = CIImage(mtlTexture: texture.texture, options: nil)
        if (testImage?.cgImage == nil) {
            
        }
        
        super.newTextureAvailable(texture, fromSourceIndex: UInt(sourceIndex), trackID: trackID)
        
        
    }
}
