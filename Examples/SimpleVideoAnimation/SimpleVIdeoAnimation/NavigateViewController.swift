//
//  NavigateViewController.swift
//  SimpleVideoTransition
//
//  Created by Ruanshengqiang Macro on 2020/7/2.
//  Copyright © 2020 Ruanshengqiang Macro. All rights reserved.
//

import UIKit
import MetalVideoProcess
import AVFoundation
import MetalVideoProcess

class NavigateViewController: UIViewController {
    @IBOutlet weak var naviStackView: UIStackView!

    var transitionTimeRange = CMTimeRange.init()
    
    let N = 11
    private func getTransition(index: Int) -> (titleName: String, transObject: MetalVideoProcessMotion) {
        switch index {
        case 0:
            return (titleName: "向上滑动", transObject: MetalVideoProcessMoveUpMotion())
        case 1:
            return (titleName: "放大", transObject: MetalVideoProcessZoomInMotion())
        case 2:
            return (titleName: "旋转", transObject: MetalVideoProcessRotateMotion())
        case 3:
            return (titleName: "渐显", transObject: MetalVideoProcessFadeInMotion())
        case 4:
            return (titleName: "向右转入", transObject: MetalVideoProcessRotateInRightMotion())
        case 5:
            return (titleName: "涡旋旋转", transObject: MetalVideoProcessSwirlMotion())
        case 6:
            return (titleName: "缩小", transObject: MetalVideoProcessZoomOutMotion())
        case 7:
            return (titleName: "向左滑入", transObject: MetalVideoProcessMoveLeftMotion())
        case 8:
            return (titleName: "向右滑入", transObject: MetalVideoProcessMoveRightMotion())
        case 9:
            return (titleName: "向上旋入", transObject: MetalVideoProcessUpMoveInBlurMotion())
        case 10:
            return (titleName: "动感缩小", transObject: MetalVideoProcessZoomOutBlurMotion())
        default:
        return (titleName: "放大", transObject: MetalVideoProcessMoveUpMotion())
        
        }
    }
    private func getButton(index: Int) -> UIButton {
        let splitNum = 5.0
        let pieceWidth = Double(self.view.frame.width) / splitNum
        let buttonWidth = pieceWidth * 0.8
        let dIndex = Double(index)
        let indexX = fmod(dIndex, splitNum) * pieceWidth
        let indexY = (floor(dIndex / splitNum)) * pieceWidth + 100.0
        
        let buttonFrame = CGRect(x: indexX, y: indexY, width: buttonWidth, height: buttonWidth)
        
        let but = UIButton(frame: buttonFrame)
        but.backgroundColor = UIColor(red: 0.3, green: 0.4, blue: 0.3, alpha: 0.7)
        but.setTitle(getTransition(index: index).titleName, for: .normal)
       
        but.titleLabel?.adjustsFontSizeToFitWidth = true
        but.addTarget(self, action: #selector(self.swithController(_:)), for: .touchUpInside)
        
        but.tag = index
        return but
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for index in 0...N - 1 {
            self.view.addSubview(getButton(index: index))
        }
    }
    
    @IBAction func swithController(_ sender: UIButton) {
        
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController")  as! ViewController
        
        let trans = getTransition(index: sender.tag)
        
        viewController.motionIn = trans.transObject
        
        self.present(viewController, animated: true, completion: nil)
    }
}


