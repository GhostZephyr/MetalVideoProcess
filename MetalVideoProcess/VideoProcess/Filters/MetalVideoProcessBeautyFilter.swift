//
//  MetalVideoProcessBeautyFilter.swift
//  MetalVideoProcessBeautyFilter
//  
//  Created by RenZhu Macro on 2020/4/22.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation

public class MetalVideoProcessBeautyFilter: MetalVideoProcessOperation  {
    
    
    public var beautyLevel = 1.0
    public var toneLevel = 0.5
    public var brightnessLevel = 0.5
    
    public var brightness: Float
    {
        get {
            uniformSettings["brightness"]
        }
        set {
            uniformSettings["brightness"] = newValue
        }
    }
    
    public var singleStepOffset: Position
    {
        get {
            uniformSettings["singleStepOffset"]
        }
        set {
            uniformSettings["singleStepOffset"] = newValue
        }
    }
    
    public var params: Color
    {
        get {
            uniformSettings["params"]
        }
        set {
            uniformSettings["params"] = newValue
        }
    }
    
    
    public init() {
        super.init(fragmentFunctionName: "beautyFilter",
                   numberOfInputs: 1, device: sharedMetalRenderingDevice)
        self.brightness = Float(self.brightnessLevel - 0.5)
        let position = Position(Float(2.0 / 720.0), Float(2.0 / 1280.0))
        self.singleStepOffset = position
        let color = Color(red: Float(1.0 - 0.6 * self.beautyLevel),
                                 green: Float(1.0 - 0.3 * self.beautyLevel),
                                 blue: Float(0.1 + 0.3 * self.toneLevel),
                                 alpha: Float(0.1 + 0.3 * self.toneLevel))
        self.params = color
    }
    
    public override func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        super.newTextureAvailable(texture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
    
}
