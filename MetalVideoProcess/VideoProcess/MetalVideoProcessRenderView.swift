//
//  MetalVideoProcessRenderView.swift
//  MetalVideoProcessRenderView
//
//  Created by RenZhu Macro on 2020/4/16.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//  用于图片 视频 相机等处理的渲染视图 兼容 RenderFilter

import Foundation
import MetalKit
import AVFoundation

public class MetalVideoProcessRenderView: MTKView, ImageConsumer {
    
    
    public var isEnable: Bool = true
    public let sources: SourceContainer = SourceContainer()
    
    /// 只支持单输入
    public let maximumInputs: UInt = 1
    var currentTexture: Texture?
    var renderPipelineState: MTLRenderPipelineState!
    let frameRenderingSemaphore = DispatchSemaphore(value: 1)
    
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt, trackID: Int32) {
        self.drawableSize = CGSize(width: texture.texture.width, height: texture.texture.height)
        currentTexture = texture
        self.draw()
    }
    
    public override func draw(_ rect: CGRect) {
        guard (frameRenderingSemaphore.wait(timeout: DispatchTime.now()) == DispatchTimeoutResult.success) else {
            return
        }
        if let currentDrawable = self.currentDrawable, let imageTexture = currentTexture {
            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
            
            commandBuffer?.addCompletedHandler({ [weak self] (_) in
                self?.frameRenderingSemaphore.signal()
            })
            
            let outputTexture = Texture(orientation: .portrait, texture: currentDrawable.texture)

            commandBuffer?.renderQuad(pipelineState: renderPipelineState, inputTextures: [0: imageTexture], outputTexture: outputTexture)
            
            commandBuffer?.present(currentDrawable)
            commandBuffer?.commit()
//            commandBuffer?.waitUntilCompleted()
            
        }
    }

    
    private func commonInit() {
        framebufferOnly = false
        autoResizeDrawable = true
        self.device = sharedMetalRenderingDevice.device
        let (pipelineState, _) = generateRenderPipelineState(device: sharedMetalRenderingDevice,
                                                             vertexFunctionName: "oneInputVertex",
                                                             fragmentFunctionName: "passthroughFragment",
                                                             operationName: "RenderView")
        self.renderPipelineState = pipelineState
        enableSetNeedsDisplay = false
        self.contentMode = .scaleAspectFit
        isPaused = true //此处pause 为true 意味着需要外部的input手动驱动渲染，如camera 或者 moviePlayer渲染每帧生成的图像
    }
    
    public func snapshotRenderView() -> CGImage? {
        return self.currentTexture?.cgImage()
    }
}
