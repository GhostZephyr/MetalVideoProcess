//
//  ResourceItem.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/7.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import MetalVideoProcess

class ResourceItem: MetalVideoEditorItem {
    
    public var rotate = 0.0
    public var scale = Position(1.0, 1.0)
    //translation 为归一化
    public var translation = Position(0.0, 0.0)
    
    var orientation : UIInterfaceOrientation = .portrait
    weak var transformFilter: MetalVideoProcessTransformFilter?
    weak var currentLayer: MetalVideoProcessBlendFilter?
    var roi: CGRect = CGRect.zero
    var fillType: MetalVideoProcessTransformFilter.StretchType = .aspectToFill
    
    var isSelected: Bool = false
    
    var startTimeText: NSString {
        get {
            return NSString(format: "%.2f", self.startTime.seconds)
        }
    }
    
    var durationText: NSString {
        get {
            return NSString(format: "%.2f", self.duration.seconds)
        }
    }
}
