//  MetalVideoProcessPlayer+CompositorDelegate.swift
//  MetalVideoProcessPlayer
//
//  Created by RenZhu Macro on 2020/6/11.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation

extension MetalVideoProcessPlayer: MetalVideoProcessCompositorDelegate {
    
    public func renderRequest(request: AVAsynchronousVideoCompositionRequest) {
        if self.isPlaying {
            self.requestCache.addRequest(time: request.compositionTime, request: request)
        } else {
            self.currentRequest = request
        }
    }
    
    public func exportRequest(request: AVAsynchronousVideoCompositionRequest) {
        let _ = self.audioEncodingTarget?.renderVideoFramesemaphore.wait(timeout: .distantFuture)
        self.videoFrameProcessingQueue.async { [weak self] in
            autoreleasepool {
                guard let `self` = self else { return }
           
                //这里开始通过request去纹理并process
                debugPrint("export:", request.compositionTime.seconds)
                self.process(request: request, newTime: request.compositionTime)
                
            }
        }
        
       
    }
    
    
}
