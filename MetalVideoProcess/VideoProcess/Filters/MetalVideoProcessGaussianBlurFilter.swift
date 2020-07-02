//
//  MetalVideoProcessGaussianBlurFilter.swift
//  MetalVideoProcessGaussianBlurFilter
//  
//  Created by wangrenzhu Macro on 2020/5/15.
//  Copyright © 2020 wangrenzhu Macro. All rights reserved.
//
import Foundation
import MetalPerformanceShaders

public class MetalVideoProcessGaussianBlurFilter: MetalVideoProcessOperation {
    deinit {
        self.removeAllTargets()
        internalMPSImageGaussianBlur = nil
    }
    
    public var blurRadiusInPixels: Float = 10.0 {
        didSet
        {
            if self.useMetalPerformanceShaders, #available(iOS 9, macOS 10.13, *) {
                internalMPSImageGaussianBlur = MPSImageGaussianBlur(device: sharedMetalRenderingDevice.device, sigma: blurRadiusInPixels)
                internalMPSImageGaussianBlur?.edgeMode = MPSImageEdgeMode.clamp
                weakMPSImageBlur = internalMPSImageGaussianBlur
                
            } else {
                fatalError("Gaussian blur not yet implemented on pre-MPS OS versions")
            }
        }
    }
    
    public var internalMPSImageGaussianBlur: MPSImageGaussianBlur?
    weak var weakMPSImageBlur: MPSImageGaussianBlur?
    
    public init() {
        super.init(fragmentFunctionName: "passthroughFragment")
        
        self.useMetalPerformanceShaders = true
        
        ({blurRadiusInPixels = 10.0})()
        
        if #available(iOS 9, macOS 10.13, *) {
            self.metalPerformanceShaderPathway = { [weak self]
                (commandBuffer: MTLCommandBuffer,
                inputTextures: [UInt: Texture],
                outputTexture: Texture) in
                    (self?.weakMPSImageBlur)?.encode(commandBuffer: commandBuffer,
                                               sourceTexture: inputTextures[0]!.texture,
                                               destinationTexture: outputTexture.texture)
            }
        } else {
            fatalError("Gaussian blur not yet implemented on pre-MPS OS versions")
        }
    }
}
