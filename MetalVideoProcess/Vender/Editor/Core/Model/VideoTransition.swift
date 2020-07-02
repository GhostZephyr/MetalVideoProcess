//
//  VideoTransition.swift
//  Cabbage
//
//  Created by Vito on 01/03/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import CoreMedia

public protocol VideoTransition: class {
    var identifier: String { get }
    var duration: CMTime { get }
    func renderImage(foregroundImage: CIImage,
                     backgroundImage: CIImage,
                     forTweenFactor tween: Float64,
                     renderSize: CGSize) -> CIImage
}

open class TransitionDuration: VideoTransition {
    public var identifier: String {
        return String(describing: self)
    }
    
    open var duration: CMTime
    
    public init(duration: CMTime = CMTime.zero) {
        self.duration = duration
    }
    
    open func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        return foregroundImage.composited(over: backgroundImage)
    }
}
