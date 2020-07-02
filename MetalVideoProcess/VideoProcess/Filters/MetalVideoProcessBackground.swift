//
//  MetalVideoProcessBackground.swift
//  MetalVideoProcessBackground
//  
//  Created by wangrenzhu Macro on 2020/5/15.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation

public class MetalVideoProcessBackground: MetalVideoProcessFilterGroup  {
    
    public override var debugName: String {
        get {
            return "background"
        }
        set {}
    }
    
    deinit {
        self.blurFilter?.removeAllTargets()
        self.blend?.removeAllTargets()
        self.colorFiter?.removeAllTargets()
        self.currentBackgroundFilter?.removeAllTargets()
        self.transform?.removeAllTargets()
        self.blurFilter = nil
        self.blend = nil
        self.colorFiter = nil
        self.currentBackgroundFilter = nil
        self.transform = nil
        self.targets.removeAll()
        for (index, source) in self.sources.sources {
            self.removeSourceAtIndex(index)
            source.removeAllTargets()
        }
    }
    
    /// 1.canvasSize Size
    /// 2.ratio 6 enum
    /// 3. none 480p 720p 1080p 2k/4k
    /// 1+2 = backgroundSize
    public enum RatioType: Double {
        case Ratio9_16 = 0.5625
        case Ratio3_4 = 0.75
        case Ratio1_1 = 1.0
        
        case Ratio4_3 = 1.333333333333333
        case Ratio16_9 = 1.777777777777778
    }
    
    public enum CanvasType {
        case TypeNone
        case Type480p
        case Type720p
        case Type1080p
        case Type2k
        case Type4k
    }
    
    public enum BackgroundType {
        case Black
        case Blur
    }
    
    
    private weak var blend: MetalVideoProcessBlendFilter?
    
    private weak var currentBackgroundFilter: MetalVideoProcessOperation?
    private weak var blurFilter: MetalVideoProcessGaussianBlurFilter?
    private weak var colorFiter: MetalVideoProcessColorFilter?
    
    public func setBackgroundType(type: BackgroundType) {
        backgroundType = type
        
        switch type {
        case .Black: 
            blurFilter?.isEnable = false
            colorFiter?.isEnable = true
            colorFiter?.color = Color(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            break
        case .Blur: 
            blurFilter?.isEnable = true
            colorFiter?.isEnable = false
            break
        }
    }
    
    public var rotate = 0.0 {
        didSet {
            transform?.rotate = rotate
        }
    }
    public var scale = Position(1.0, 1.0) {
        didSet {
            transform?.scale = scale;
        }
    }
    public var translation = Position(0.0, 0.0)
    
    public static var canvasSize: CGSize = CGSize(width: 1000, height: 1000)
    
    public var aspectRatioType: RatioType = .Ratio1_1 {
        didSet {
            MetalVideoProcessBackground.canvasSize = getCanvas()
        }
    }
    
    public var canvasSizeType: CanvasType = .TypeNone {
        didSet {
            MetalVideoProcessBackground.canvasSize = getCanvas()
        }
    }
    
    private var backgroundType: BackgroundType = .Black
    
    private var _mvp: Matrix4x4 = Matrix4x4.identity
    private var sourceSize: CGSize? = nil
    public var transform: MetalVideoProcessTransformFilter?
    
    public func getCanvas() -> CGSize {
        switch(canvasSizeType) {
        case .TypeNone: 
            return getCanvasAsCanvasSizeType(pixel: Double(MetalVideoProcessBackground.canvasSize.width))
        case .Type480p: 
            return getCanvasAsCanvasSizeType(pixel: 480)
        case .Type720p: 
            return getCanvasAsCanvasSizeType(pixel: 720)
        case .Type1080p: 
            return getCanvasAsCanvasSizeType(pixel: 1080)
        case .Type2k: 
            return getCanvasAsCanvasSizeType(pixel: 2560)
        case .Type4k: 
            return getCanvasAsCanvasSizeType(pixel: 3840)
        }
    }
    
    public func getCanvasAsCanvasSizeType(pixel: Double) -> CGSize {
        if (aspectRatioType.rawValue > 1.0) {
            return CGSize(width: pixel * aspectRatioType.rawValue, height: pixel)
        } else {
            return CGSize(width: pixel, height: pixel / aspectRatioType.rawValue)
        }
    }
    
    public override init(trackID: Int32) {
        super.init(trackID: trackID)
        self.trackID = trackID
        
        let transform = MetalVideoProcessTransformFilter()
        transform.debugName = "bg Transform"
        self.transform = transform
        
        let blurFilter = MetalVideoProcessGaussianBlurFilter()
        blurFilter.debugName = "bg Blur"
        self.blurFilter = blurFilter
        self.blurFilter?.isEnable = false

        let colorFiter = MetalVideoProcessColorFilter()
        colorFiter.debugName = "bg Color"
        self.colorFiter = colorFiter
        
        
        self.configureGroup{input, output in
            input --> transform --> blurFilter --> colorFiter --> output
        }
    }
    
    public override func newTextureAvailable(_ inputTexture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        
        let renderSize = MetalVideoProcessBackground.canvasSize
        
        let ratio = CGSize(width: CGFloat(renderSize.width) / CGFloat(inputTexture.texture.width), height: CGFloat(renderSize.height) / CGFloat(inputTexture.texture.height))
        
        var pro: CGSize
        
        let len = sqrt(Float(renderSize.width * renderSize.width + renderSize.height * renderSize.height) * 0.25)
        var scale: Float
        if (ratio.width > ratio.height) {
            pro = CGSize(width: ratio.height / ratio.width, height: 1.0)
            let proInPixel = CGSize(width: pro.width * renderSize.width, height: renderSize.height)
            scale = len * 2.0 / Float(proInPixel.width)
            
        } else {
            pro = CGSize(width: 1.0, height: ratio.width / ratio.height)
            let proInPixel = CGSize(width: renderSize.width, height: pro.height * renderSize.height)
            scale = len * 2.0 / Float(proInPixel.height)
        }
        
        self.scale = Position(scale, scale)
        super.newTextureAvailable(inputTexture, fromSourceIndex: fromSourceIndex, trackID: trackID)
    }
    
}
