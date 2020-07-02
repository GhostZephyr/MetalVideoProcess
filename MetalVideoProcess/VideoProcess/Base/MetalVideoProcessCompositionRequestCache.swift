//
//  MetalVideoProcessCompositionRequestCache.swift
//  MetalVideoProcessCompositionRequestCache
//
//  Created by RenZhu Macro on 2020/6/5.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation

public class MetalVideoProcessCompositionRequestCache {
    
    public var maxSize = 30 //最多30帧
    private var poolSemaphare = DispatchSemaphore(value: 1)
    
    public var requestCacheDictionary: [NSValue: AVAsynchronousVideoCompositionRequest] = [: ]
    
    deinit {
        poolSemaphare.signal()
        self.requestCacheDictionary.removeAll()
    }
    
    public func clearCacheWithTime(_ time: CMTime) {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        let removeList = self.requestCacheDictionary.filter { $1.compositionTime < time }
        debugPrint("remove cache: ", removeList.count)
//        self.requestCacheDictionary.removeAll()
        for item in removeList {
            self.requestCacheDictionary.removeValue(forKey: item.key)
        }
        poolSemaphare.signal()
    }
    
    public func addRequest(time: CMTime, request: AVAsynchronousVideoCompositionRequest) {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        let key = NSValue(time: time)
        
        self.requestCacheDictionary[key] = request
        
        if self.requestCacheDictionary.keys.count > maxSize {
            
            
            guard let firstKey = self.requestCacheDictionary.keys.first else { return }
            guard let index = self.requestCacheDictionary.keys.firstIndex(of: firstKey) else {
                return
            }
            self.requestCacheDictionary.remove(at: index)
        }
        poolSemaphare.signal()
    }
    
    public func removeRequest(time: CMTime) {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        let key = NSValue(time: time)
        self.requestCacheDictionary.removeValue(forKey: key)
        
        
        poolSemaphare.signal()
    }
    
    public func getRequest(time: CMTime) -> AVAsynchronousVideoCompositionRequest? {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        let key = NSValue(time: time)
        let request = requestCacheDictionary[key]
        poolSemaphare.signal()
        return request
    }
    
    public func clearAllRequest() {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        self.requestCacheDictionary.removeAll()
        poolSemaphare.signal()
    }
    
    public func removeAll() {
        let _ = poolSemaphare.wait(timeout: .distantFuture)
        self.requestCacheDictionary.removeAll()
        poolSemaphare.signal()
    }
}
