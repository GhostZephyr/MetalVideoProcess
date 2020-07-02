//
//  MBProgressHUDExtension.swift
//  LisPonOrbit
//
//  Created by v_fanxingxing on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

import UIKit

enum HubShowType {
    case loading(String)
    case succees(String)
    case failed(String)
}

extension MBProgressHUD {


    /** 只显示消息*/
    static func showMsg(_ message: String, dismissInSeconds secondes: Double = 1.25, yOffset: Float? = 0, _ inView: UIView? = nil,isUserInteractionEnabled: Bool = false, completion: (() -> Void)? = nil) -> Void {
        DispatchQueue.main.async {
            var container: UIView? = nil
            if let view = inView {
                container = view
            } else {
                container = UIApplication.shared.keyWindow
            }
            
            let hud = MBProgressHUD.showAdded(to: container!, animated: true)
            hud.mode = .text
            hud.detailsLabel.text = message
            hud.label.font = UIFont.systemFont(ofSize: 13)
            hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            hud.margin = 15
            hud.offset.y = CGFloat(yOffset ?? 0)
            hud.isUserInteractionEnabled = isUserInteractionEnabled
            hud.completionBlock = completion
            hud.hide(animated: true, afterDelay: secondes)
        }
    }

    /** 显示文字和图片*/
    static func showHub(with type: HubShowType, _ inView: UIView? = nil, isUserInteractionEnabled: Bool = false) -> MBProgressHUD {
        var container: UIView? = nil
        if let view = inView {
            container = view
        } else {
            container = UIApplication.shared.keyWindow
        }
        
        let hud = MBProgressHUD.showAdded(to: container!, animated: true)
        
        switch type {
        case let .succees(content):
            hud.mode = .indeterminate
            
            hud.detailsLabel.text = content
            hud.isUserInteractionEnabled = isUserInteractionEnabled
            hud.hide(animated: true, afterDelay: 1.25)
        case let .failed(content):
            hud.mode = .customView
            let img = UIImage(named: "wk_failed")
            let imageView = UIImageView(image: img)
            hud.customView = imageView
            hud.detailsLabel.text = content
            hud.isUserInteractionEnabled = isUserInteractionEnabled
            hud.hide(animated: true, afterDelay: 1.25)
        case let .loading(content):
            hud.mode = .determinateHorizontalBar
            hud.isUserInteractionEnabled = isUserInteractionEnabled
            hud.detailsLabel.text = content
        }
        
        hud.label.font = UIFont.systemFont(ofSize: 13)
        hud.animationType = .zoom
        hud.removeFromSuperViewOnHide = true
        hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        hud.layer.cornerRadius = 4
        hud.show(animated: true)
        return hud
    }
    
    static func showCustom(image imgStr: String, title titleStr: String, isUserInteractionEnabled: Bool = false, autoHide: Bool = true, delayHide: TimeInterval = 2) {
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
            hud.label.text = titleStr
            hud.label.textColor = .white
            hud.label.font = UIFont.systemFont(ofSize: 17)
            hud.label.numberOfLines = 0
            hud.isUserInteractionEnabled = isUserInteractionEnabled
            
            hud.customView = UIImageView(image: UIImage(named: imgStr))
            hud.bezelView.backgroundColor = UIColor.black.withAlphaComponent(0.6)    //背景颜色
            // 再设置模式
            hud.mode = .customView;
            hud.margin = 20
            if autoHide {
                hud.hide(animated: true, afterDelay: delayHide)
            }
        }
    }

    /** 隐藏hud*/
    static func dismiss() {
        DispatchQueue.main.async {
            let container: UIView? = UIApplication.shared.keyWindow
            guard let appWindow = container else { return }
            MBProgressHUD.hide(for: appWindow, animated: true)
        }
    }

}
