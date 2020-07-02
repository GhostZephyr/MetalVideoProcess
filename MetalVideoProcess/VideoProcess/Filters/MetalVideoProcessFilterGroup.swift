//
//  MetalVideoProcessFilterGroup.swift
//
//  Created by RenZhu Macro on 2020/4/23.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation

open class MetalVideoProcessFilterGroup: ImageProcessingOperation {
    public var debugName: String = ""
    
    public var trackID: Int32 = 0
    
    public var isEnable: Bool = true
    
    let inputImageRelay = ImageRelay()
    let outputImageRelay = ImageRelay()
    
    public var sources: SourceContainer { get { return inputImageRelay.sources } }
    public var targets: TargetContainer { get { return outputImageRelay.targets } }
    public let maximumInputs: UInt = 1
    
    public init(trackID: Int32) {
        self.trackID = trackID
    }
    
    open func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        inputImageRelay.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
    
    public func configureGroup(_ configurationOperation: (_ input: ImageRelay, _ output: ImageRelay) -> ()) {
        configurationOperation(inputImageRelay, outputImageRelay)
    }
    
    public func transmitPreviousImage(to target: ImageConsumer, atIndex: UInt, trackID: Int32) {
        outputImageRelay.transmitPreviousImage(to: target, atIndex: atIndex, trackID: trackID)
    }
}
