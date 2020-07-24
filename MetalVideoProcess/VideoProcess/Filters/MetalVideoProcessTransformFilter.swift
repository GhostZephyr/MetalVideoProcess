//
//  MetalVideoProcessTransformFilter.swift
//  MetalVideoProcessTransformFilter
//  
//  Created by RenZhu Macro on 2020/5/15.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import AVFoundation

public class MetalVideoProcessTransformFilter: MetalVideoProcessOperation  {
    
    public var rotate = 0.0
    public var scale = Position(1.0, 1.0)
    //translation 为归一化
    public var translation = Position(0.0, 0.0)
   
    public var roi: CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0) {
        didSet {
            
            let roiAdjusted = CGRect(x: roi.origin.x, y: 1.0 - roi.origin.y, width: roi.width, height: roi.height)
            self.translation =  Position(Float(roiAdjusted.origin.x * 2.0 + roiAdjusted.size.width) - 1.0, Float(roiAdjusted.origin.y * 2.0 - roiAdjusted.size.height) - 1.0)
            self.scale = Position(Float(roiAdjusted.size.width), Float(roiAdjusted.size.height))
        }
    }
    
    public enum StretchType {
        case scaleToFill
        case aspectToFit
        case aspectToFill
    }
    
    public enum outTextureSizeType {
        case asInputTextureSize
        case asCanvasSize
        case asUserDefined
    }
    
    public var stretchType: StretchType = .aspectToFit
    public var outTextureSizeType: outTextureSizeType = .asCanvasSize
    
    public var renderSize: CGSize? = MetalVideoProcessBackground.canvasSize
    private var _iResolution: Position = Position(1.0, 1.0)
    private var _mvp: Matrix4x4 = Matrix4x4.identity
    
    private var iResolution: Position
    {
        get {
            return _iResolution
        }
        set {
            uniformSettings["iResolution"] = newValue
            _iResolution = newValue
        }
    }
    
    private var mvp: Matrix4x4
    {
        get {
            return _mvp
        }
        set {
            uniformSettings["mvp"] = newValue
            _mvp = newValue
        }
    }
    
    private var feather: Float
    {
        get {
            return uniformSettings["feather"]
        }
        set {
            uniformSettings["feather"] = newValue
        }
    }
    
    public init() {
        super.init(vertexFunctionName: "transformVertex", fragmentFunctionName: "transformFragment",
                   numberOfInputs: 1, device: sharedMetalRenderingDevice)
        let renderSize = MetalVideoProcessBackground.canvasSize
        self.iResolution = Position(Float(renderSize.width), Float( renderSize.height))
        var tranform = CGAffineTransform(translationX: CGFloat(0.0), y: CGFloat(0.0))
        tranform = tranform.rotated(by: CGFloat(0.0))
        tranform = tranform.scaledBy(x: renderSize.width, y: renderSize.height)
        mvp = Matrix4x4.init(tranform);
    }
    
    public override func newTextureAvailable(_ inputTexture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        
        switch self.outTextureSizeType {
            case .asCanvasSize: 
                self.renderSize = MetalVideoProcessBackground.canvasSize
                self.iResolution = Position(Float(MetalVideoProcessBackground.canvasSize.width),
                                            Float(MetalVideoProcessBackground.canvasSize.height));
                break;
            
            case .asInputTextureSize: 
                self.renderSize = CGSize(width: CGFloat(inputTexture.texture.width), height: CGFloat(inputTexture.texture.height))
                self.iResolution = Position(Float(inputTexture.texture.width), Float(inputTexture.texture.height))
                break;
            
            case .asUserDefined: 
                self.iResolution = Position(Float(self.renderSize!.width), Float( self.renderSize!.height))
                break;
        }
        
        let ratio = CGSize(width: CGFloat(renderSize!.width) / CGFloat(inputTexture.texture.width), height: CGFloat(renderSize!.height) / CGFloat(inputTexture.texture.height))
        var transform = CGAffineTransform(translationX: CGFloat(translation.x) * self.renderSize!.width, y: CGFloat(translation.y) * self.renderSize!.height)
        let radRotate = rotate * Double.pi / 180.0
        transform = transform.rotated(by: CGFloat(radRotate))

        var pro: CGSize;
        switch stretchType {
        case .scaleToFill: 
            pro = CGSize(width: 1.0, height: 1.0)
            break
        case .aspectToFit: 
            if (ratio.width > ratio.height) {
                pro = CGSize(width: ratio.height / ratio.width, height: 1.0)
            } else {
                pro = CGSize(width: 1.0, height: ratio.width / ratio.height)
            }
            break
        case .aspectToFill: 
            if (ratio.width < ratio.height) {
                pro = CGSize(width: ratio.height / ratio.width, height: 1.0)
            } else {
                pro = CGSize(width: 1.0, height: ratio.width / ratio.height)
            }
            break
        }
        
        transform = transform.scaledBy(x: CGFloat(scale.x) * pro.width, y: CGFloat(scale.y) * pro.height)
        
        mvp = Matrix4x4.init(transform);
        super.newTextureWithSize(inputTexture, fromSourceIndex: fromSourceIndex, renderSize: renderSize!, trackID: trackID)
    }
    
}
