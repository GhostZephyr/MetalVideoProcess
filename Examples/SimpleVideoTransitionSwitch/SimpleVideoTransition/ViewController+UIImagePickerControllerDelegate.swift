//
//  ViewController+UIImagePickerControllerDelegate.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/9.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import AVFoundation
import MobileCoreServices

func orientationForTrack(asset: AVAsset) -> UIInterfaceOrientation {
    let track = asset.tracks(withMediaType: .video).first
    guard let txf = track?.preferredTransform else {
        return .portrait
    }
    if txf.a == 0 && txf.b == 1.0 && txf.c == -1.0 && txf.d == 0 {
        return .landscapeRight
    } else if txf.a == 0 && txf.b == -1.0 && txf.c == 1.0 && txf.d == 0 {
        return .landscapeLeft
    } else if txf.a == 1.0 && txf.b == 0 && txf.c == 0 && txf.d == 1.0 {
        return .portrait
    } else if txf.a == -1.0 && txf.b == 0 && txf.c == 0 && txf.d == -1.0 {
        return .portraitUpsideDown
    } else {
        return .unknown
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        debugPrint("info:", info)
        picker.dismiss(animated: true, completion: nil)
        guard let mediaType = info[.mediaType] else {
            return
        }
        
        if mediaType as! CFString == kUTTypeMovie {
            debugPrint("video")
            guard let url = info[.mediaURL] as? URL else {
                return
            }
            
            let asset = AVAsset(url: url)
            let orientation = orientationForTrack(asset: asset)
            
            debugPrint("asset:", asset)
            let item = ResourceItem(asset: asset)
            
            item.fillType = .aspectToFill
            item.orientation = orientation
            switch item.orientation {
            case .portrait:
                break
            case .landscapeLeft:
                item.rotate = 90.0
                break
            case .landscapeRight:
                item.rotate = -90.0
                break
            case .portraitUpsideDown:
                item.rotate = 180.0
                break
            default:
                break
            }
            
            if picker == self.subPicker {
                try? self.videoEditor?.insertOverlayItem(overlayItem: item)
                item.roi = CGRect(x: 0.4, y: 0.4, width: 0.8, height: 0.8)
                self.subResources.append(item)
            } else {
                
                try? self.videoEditor?.insertItem(videoItem: item)
                item.roi = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
                self.mainResources.append(item)
            }
            self.rebuildPipeline()
            self.subTableView.reloadData()
            self.mainTableView.reloadData()
            
        } else {
            debugPrint("unsupported")
            return
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
    }
    
    
}
