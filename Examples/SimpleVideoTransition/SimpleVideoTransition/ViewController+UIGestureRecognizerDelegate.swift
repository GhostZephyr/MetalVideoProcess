//
//  ViewController+UIGestureRecognizerDelegate.swift
//  SimpleVideoEditor
//
//  Created by RenZhu Macro on 2020/7/9.
//  Copyright © 2020 RenZhu Macro. All rights reserved.
//

import Foundation
import MetalVideoProcess

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
    
    @IBAction func rotateAction(ges: UIRotationGestureRecognizer) {
        guard let item = (self.mainSelectedItem != nil ? self.mainSelectedItem : self.subSelectedItem) else {
            return
        }
        guard let transformFilter = item.transformFilter else {
            return
        }
        let rotDeg = transformFilter.rotate + Double(-ges.velocity)
        transformFilter.rotate = rotDeg
        item.rotate = rotDeg
    }
    
    @IBAction func pinchAction(ges: UIPinchGestureRecognizer) {
        guard let item = (self.mainSelectedItem != nil ? self.mainSelectedItem : self.subSelectedItem) else {
            return
        }
        guard let transformFilter = item.transformFilter else {
            return
        }
        transformFilter.scale = Position((transformFilter.scale.x) + Float(ges.velocity * 0.01), (transformFilter.scale.y) + Float(ges.velocity * 0.01))
        var x: Float = (transformFilter.scale.x)
        var y: Float = (transformFilter.scale.y)
        if ((transformFilter.scale.x) < 0.01) {
            x = 0.01
        }
        if ((transformFilter.scale.y) < 0.01) {
            y = 0.01
        }
        transformFilter.scale = Position(x, y)
        item.scale = transformFilter.scale
    }
    
    @IBAction func panAction(ges: UIPanGestureRecognizer) {
        guard let item = (self.mainSelectedItem != nil ? self.mainSelectedItem : self.subSelectedItem) else {
            return
        }
        guard let transformFilter = item.transformFilter else {
            return
        }
        
        if ges.state == .changed {
            let tanl = ges.translation(in: ges.view)
            
            // have to content the view scaleFactor and the vertex to texture scale.
            transformFilter.translation = Position(currentPostion.x + Float(tanl.x * self.renderView.contentScaleFactor * 2.0) / Float(self.renderView.drawableSize.width), currentPostion.y - Float(tanl.y * self.renderView.contentScaleFactor * 2.0) / Float(self.renderView.drawableSize.height))
            
        } else if ges.state == .ended {
            currentPostion = (transformFilter.translation)
        }
        
        item.translation = transformFilter.translation
    }
    
    
}
